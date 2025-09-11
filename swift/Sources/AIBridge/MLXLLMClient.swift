import Foundation
import MLX
import MLXNN
import MLXOptimizers
import MLXRandom
import MLXLLM
import MLXLMCommon

/// Client for local LLM models using MLX Swift
public final class MLXLLMClient: ObservableObject, @unchecked Sendable {
    
    public enum Model: String, CaseIterable {
        // Elite models - leverage unified memory for larger models
        case deepseek_r1_distill_qwen_32B = "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit"
        case qwen25_32B = "mlx-community/Qwen2.5-32B-Instruct-4bit"
        case qwen25_14B = "mlx-community/Qwen2.5-14B-Instruct-4bit"
        
        // Standard models - 4-bit quantized from MLX Community  
        case qwen25_7B = "mlx-community/Qwen2.5-7B-Instruct-4bit"
        case llama32_3B = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        case mistral7B = "mlx-community/Mistral-7B-Instruct-v0.3-4bit"
        
        var hubPath: String {
            return self.rawValue
        }
        
        var localPath: String {
            // Local path where models are stored
            let home = FileManager.default.homeDirectoryForCurrentUser
            
            // Extract model name from the hub path
            // mlx-community/Qwen2.5-3B-Instruct-4bit -> Qwen2.5-3B-Instruct-4bit
            let modelName = self.rawValue.split(separator: "/").last ?? "model"
            let modelPath = home.appendingPathComponent("models/\(modelName)").path
            
            // Check if directory exists
            if FileManager.default.fileExists(atPath: modelPath) {
                return modelPath
            }
            
            // Fallback to checking without version numbers in case of variations
            let baseModelName = String(modelName).replacingOccurrences(of: "2.5", with: "25")
            let altPath = home.appendingPathComponent("models/\(baseModelName)").path
            if FileManager.default.fileExists(atPath: altPath) {
                return altPath
            }
            
            return modelPath // Return original path if nothing found
        }
        
        var priority: Priority {
            switch self {
            case .deepseek_r1_distill_qwen_32B, .qwen25_32B:
                return .critical
            case .qwen25_14B:
                return .high
            case .qwen25_7B, .mistral7B:
                return .medium
            case .llama32_3B:
                return .low
            }
        }
    }
    
    public enum Priority {
        case critical
        case high
        case medium
        case low
    }
    
    @MainActor @Published public var isLoading = false
    @MainActor @Published public var progress: Double = 0.0
    @MainActor @Published public var currentOutput = ""
    
    private var modelContainer: ModelContainer?
    private var currentModel: Model?
    
    public init() {
        // GPU cache will be set when loading a model
    }
    
    /// Check if any MLX models are available locally
    public func isAvailable() -> Bool {
        for model in Model.allCases {
            if FileManager.default.fileExists(atPath: model.localPath) {
                return true
            }
        }
        return false
    }
    
    /// Load a specific model
    public func loadModel(_ model: Model) async throws {
        if currentModel == model && modelContainer != nil {
            return // Model already loaded
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        // MLX-Swift handles local caching automatically
        // Always use the hub ID and let MLX manage the local cache
        let configuration = ModelConfiguration(
            id: model.hubPath,
            overrideTokenizer: nil
        )
        
        print("🔍 Loading model: \(model.hubPath)")
        
        // Check if we have local files (for informational purposes)
        let localPath = model.localPath
        if FileManager.default.fileExists(atPath: localPath) {
            print("✅ Found cached model files at: \(localPath)")
            print("   MLX will use cached version if compatible")
        } else {
            print("📥 Model will be downloaded from Hugging Face hub")
        }
        
        do {
            print("🚀 Initializing model with hub ID: \(configuration.id)")
            
            // Configure MLX for unified memory architecture
            // On Apple Silicon, we can use all available memory efficiently
            // Set cache to 0 for unlimited - let Metal manage memory paging
            MLX.GPU.set(cacheLimit: 0) // Unlimited - use unified memory efficiently
            
            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: configuration
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.progress = progress.fractionCompleted
                }
                if progress.fractionCompleted < 1.0 {
                    print("Progress: \(Int(progress.fractionCompleted * 100))%")
                }
            }
            currentModel = model
            print("✅ Model loaded successfully: \(model.rawValue)")
        } catch {
            print("❌ Failed to load model: \(error)")
            print("   Error details: \(String(describing: error))")
            
            // Provide helpful error messages
            if "\(error)".contains("fileNotFound") {
                print("💡 Tip: Make sure the model is available on Hugging Face")
                print("   Hub ID: \(model.hubPath)")
            } else if "\(error)".contains("offlineModeError") {
                print("💡 Tip: Check your internet connection or use a local model")
            }
            
            throw error
        }
    }
    
    /// Select best available model based on priority
    public func selectModel(for priority: Priority) -> Model? {
        // First try to find a model matching the priority
        let availableModels = Model.allCases.filter { model in
            FileManager.default.fileExists(atPath: model.localPath)
        }
        
        if availableModels.isEmpty {
            // No local models, return a default for downloading
            switch priority {
            case .critical:
                return .deepseek_r1_distill_qwen_32B
            case .high:
                return .qwen25_14B
            case .medium:
                return .qwen25_7B
            case .low:
                return .llama32_3B
            }
        }
        
        // Find best match for priority
        switch priority {
        case .critical:
            return availableModels.first { $0.priority == .critical }
                ?? availableModels.first { $0.priority == .high }
                ?? availableModels.first { $0.priority == .medium }
                ?? availableModels.first
        case .high:
            return availableModels.first { $0.priority == .high } 
                ?? availableModels.first { $0.priority == .medium }
                ?? availableModels.first
        case .medium:
            return availableModels.first { $0.priority == .medium }
                ?? availableModels.first { $0.priority == .low }
                ?? availableModels.first
        case .low:
            return availableModels.first { $0.priority == .low }
                ?? availableModels.first
        }
    }
    
    /// Generate text using the loaded model
    public func generate(
        prompt: String,
        systemPrompt: String = "You are a helpful assistant.",
        maxTokens: Int = 2048,
        temperature: Float = 0.7
    ) async throws -> String {
        
        guard let container = modelContainer else {
            throw NSError(
                domain: "MLXLLMClient",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "No model loaded"]
            )
        }
        
        await MainActor.run { currentOutput = "" }
        
        let parameters = GenerateParameters(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: 0.95,
            repetitionPenalty: 1.1
        )
        
        let result = try await container.perform { context in
            // Prepare the input with system and user prompts
            let messages: [[String: String]] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
            
            let input = try await context.processor.prepare(
                input: .init(messages: messages)
            )
            
            // Generate response
            return try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            ) { [weak self] tokens in
                // Decode partial output
                let partial = context.tokenizer.decode(tokens: tokens)
                
                Task { @MainActor in
                    self?.currentOutput = partial
                }
                
                // Continue generating until max tokens or stop token
                return tokens.count >= maxTokens ? .stop : .more
            }
        }
        
        return result.output
    }
    
    /// Generate a PRD using local LLM with structured approach
    public func generatePRD(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        userAnswers: [String: String] = [:]
    ) async throws -> String {
        
        // Select appropriate model based on priority
        let taskPriority: Priority = {
            switch priority.lowercased() {
            case "critical": return .critical
            case "high": return .high
            case "medium": return .medium
            default: return .low
            }
        }()
        
        guard let selectedModel = selectModel(for: taskPriority) else {
            throw NSError(
                domain: "MLXLLMClient",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No suitable model available. Please download models first."]
            )
        }
        
        // Load the selected model
        try await loadModel(selectedModel)
        
        // Simple PRD generation without the complex StructuredPRDGenerator
        let prdPrompt = """
        Generate a comprehensive Product Requirements Document (PRD) for:
        
        Feature: \(feature)
        Context: \(context)
        Priority: \(priority)
        Requirements: \(requirements.joined(separator: ", "))
        
        Include the following sections:
        1. Executive Summary
        2. Problem Statement
        3. User Stories
        4. Functional Requirements
        5. Non-Functional Requirements
        6. Success Metrics
        7. Technical Considerations
        8. Timeline
        9. Risks and Mitigations
        
        Format as a clear, structured document.
        """
        
        let prdResponse = try await generate(
            prompt: prdPrompt,
            systemPrompt: "You are a Product Requirements Document generator. Create comprehensive, structured PRDs.",
            maxTokens: 4096,
            temperature: 0.7
        )
        
        return prdResponse
    }
    
    /// Download a model from Hugging Face
    public func downloadModel(_ model: Model) async throws {
        print("📥 Downloading model: \(model.rawValue)")
        
        // This will trigger download through MLXModelFactory
        try await loadModel(model)
        
        print("✅ Model downloaded and loaded successfully")
    }
    
    /// Get list of available local models
    public func getAvailableModels() -> [Model] {
        return Model.allCases.filter { model in
            FileManager.default.fileExists(atPath: model.localPath)
        }
    }
}
