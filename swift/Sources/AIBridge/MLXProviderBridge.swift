import Foundation
import AIProviders

/// Bridge to connect MLXLocalProvider with MLXLLMClient
/// This avoids circular dependencies between modules
public final class MLXProviderBridge {
    
    private let mlxClient: MLXLLMClient
    
    public init() {
        self.mlxClient = MLXLLMClient()
        // Models will be loaded on-demand when needed
    }
    
    /// Create an MLXLocalProvider with actual MLX functionality
    public func createProvider() -> LLMProvider {
        return MLXLocalProviderImpl(mlxClient: mlxClient)
    }
    
    /// Implementation of MLXLocalProvider with actual MLX support
    private class MLXLocalProviderImpl: LLMProvider {
        public let name = "mlx_local"
        private let mlxClient: MLXLLMClient
        
        init(mlxClient: MLXLLMClient) {
            self.mlxClient = mlxClient
        }
        
        public func generate(_ req: LLMRequest) async throws -> LLMResponse {
            // Check if MLX is available first
            guard mlxClient.isAvailable() else {
                throw NSError(
                    domain: "MLXProvider",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No MLX models available locally. Please download models or use external providers."]
                )
            }
            
            let startTime = Date()
            
            // Convert to MLX format
            var prompt = ""
            if let system = req.system {
                prompt += "System: \(system)\n\n"
            }
            for message in req.messages {
                prompt += "\(message.role): \(message.content)\n"
            }
            
            let response = try await mlxClient.generate(
                prompt: prompt,
                systemPrompt: req.system ?? "",
                temperature: Float(req.temperature)
            )
            
            let latency = Int(Date().timeIntervalSince(startTime) * 1000)
            
            return LLMResponse(
                text: response,
                provider: name,
                latencyMs: latency
            )
        }
        
        public func isAvailable() -> Bool {
            return mlxClient.isAvailable()
        }
    }
}