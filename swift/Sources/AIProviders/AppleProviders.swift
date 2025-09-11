import Foundation
import FoundationModels

// MARK: - Apple On-Device Provider

public final class AppleOnDeviceProvider: LLMProvider {
    public let name = "apple_on_device"
    private let capabilities = DeviceCapabilities.probe()
    
    public init() {}
    
    public func generate(_ req: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        var response = ""
        
        if #available(macOS 16.0, iOS 26.0, *) {
            // Use Foundation Models framework
            let model = SystemLanguageModel.default
            
            // Check availability
            guard model.isAvailable else {
                throw NSError(
                    domain: "AppleOnDevice",
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence not available on this device"]
                )
            }
            
            // Build prompt from request
            var promptText = ""
            if let system = req.system {
                promptText += system + "\n\n"
            }
            for message in req.messages {
                promptText += "\(message.role): \(message.content)\n"
            }
            
            // Create session and generate
            let session = LanguageModelSession(instructions: req.system ?? "")
            let output = try await session.respond(to: promptText)
            response = output.content
        } else {
            // Fallback for older OS versions
            throw NSError(
                domain: "AppleOnDevice",
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: "Foundation Models requires macOS 16.0 or iOS 26.0"]
            )
        }
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return LLMResponse(
            text: response,
            provider: name,
            latencyMs: latency
        )
    }
    
    public func isAvailable() -> Bool {
        return capabilities.hasFoundationModels
    }
}

// MARK: - Apple PCC Provider

public final class ApplePCCProvider: LLMProvider {
    public let name = "apple_pcc"
    private let capabilities = DeviceCapabilities.probe()
    
    public init() {}
    
    public func generate(_ req: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        var response = ""
        
        if #available(macOS 16.0, iOS 26.0, *) {
            // Use Foundation Models with Private Cloud Compute configuration
            let model = SystemLanguageModel.default // PCC is automatic escalation
            
            // Check availability
            guard model.isAvailable else {
                throw NSError(
                    domain: "ApplePCC",
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence not available"]
                )
            }
            
            // Build prompt from request
            var promptText = ""
            if let system = req.system {
                promptText += system + "\n\n"
            }
            for message in req.messages {
                promptText += "\(message.role): \(message.content)\n"
            }
            
            // Create session with PCC preference and generate
            let session = LanguageModelSession(instructions: req.system ?? "")
            let output = try await session.respond(to: promptText)
            response = output.content
        } else {
            throw NSError(
                domain: "ApplePCC",
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: "Foundation Models requires macOS 16.0 or iOS 26.0"]
            )
        }
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return LLMResponse(
            text: response,
            provider: name,
            latencyMs: latency
        )
    }
    
    public func isAvailable() -> Bool {
        return capabilities.supportsPCC
    }
}

// MARK: - MLX Local Provider (Fallback)

public final class MLXLocalProvider: LLMProvider {
    public let name = "mlx_local"
    
    public init() {}
    
    public func generate(_ req: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        
        // Convert to MLX format
        var prompt = ""
        if let system = req.system {
            prompt += "System: \(system)\n\n"
        }
        for message in req.messages {
            prompt += "\(message.role): \(message.content)\n"
        }
        
        // Stub implementation - actual MLX handling will be done in AIBridge
        let response = "[MLX Local Response - Stub]\n" +
                      "This is a placeholder. The actual MLX implementation\n" +
                      "is handled by MLXLLMClient in the AIBridge module."
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return LLMResponse(
            text: response,
            provider: name,
            latencyMs: latency
        )
    }
    
    public func isAvailable() -> Bool {
        // Check if models directory exists
        let fm = FileManager.default
        let homeDir = fm.homeDirectoryForCurrentUser
        let modelsPath = homeDir.appendingPathComponent("models")
        return fm.fileExists(atPath: modelsPath.path)
    }
}