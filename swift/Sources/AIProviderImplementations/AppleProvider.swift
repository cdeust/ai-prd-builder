import Foundation
import AIProvidersCore
import CommonModels
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's Foundation Models provider using Apple Intelligence
/// Uses the SystemLanguageModel for on-device and Private Cloud Compute
public class AppleProvider: AIProvider {

    public let name = "Apple Foundation Models"
    private let processingMode: ProcessingMode

    public enum ProcessingMode {
        case onDevice
        case privateCloudCompute
        case hybrid
    }

    public init(mode: ProcessingMode = .hybrid) {
        self.processingMode = mode
    }

    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        DebugLogger.debug("Received \(messages.count) messages", prefix: "AppleProvider")

        #if canImport(FoundationModels)
        if #available(macOS 16.0, iOS 18.0, *) {
            do {
                DebugLogger.debug("Using Foundation Models...", prefix: "AppleProvider")
                // Use SystemLanguageModel
                let model = SystemLanguageModel.default

                // Check availability
                guard model.isAvailable else {
                    DebugLogger.debug("Model not available", prefix: "AppleProvider")
                    return .failure(.notConfigured)
                }

                // Build prompt from messages
                var promptText = ""
                for message in messages {
                    switch message.role {
                    case .system:
                        promptText += "[SYSTEM] \(message.content)\n\n"
                    case .user:
                        promptText += "[USER] \(message.content)\n"
                    case .assistant:
                        promptText += "[ASSISTANT] \(message.content)\n"
                    }
                }

                // Debug output is ON by default for development
                let isProduction = ProcessInfo.processInfo.environment["PRODUCTION"] == "true"

                #if DEBUG
                    let showDebugOutput = true
                #else
                    let showDebugOutput = !isProduction
                #endif

                // Simple progress indicator - no prompt display
                DebugLogger.debug("\n📤 Processing request (\(promptText.count) chars)...")

                // Extract system instruction if present
                let systemInstruction = messages.first(where: { $0.role == .system })?.content ?? ""

                // Create session and generate response
                let session = LanguageModelSession(instructions: systemInstruction)
                let output = try await session.respond(to: promptText)

                // Show full response for debugging
                if DebugLogger.isDebugEnabled {
                    DebugLogger.debug("\n" + String(repeating: "─", count: 80))
                    DebugLogger.debug("📥 APPLE INTELLIGENCE RESPONSE:")
                    DebugLogger.debug(String(repeating: "─", count: 80))

                    // Show the complete response for analysis
                    DebugLogger.debug(output.content)

                    // Add summary info for quick understanding
                    DebugLogger.debug(String(repeating: "─", count: 80))
                    DebugLogger.debug("📊 Response Stats:")
                    DebugLogger.debug("   • Length: \(output.content.count) characters")
                    DebugLogger.debug("   • Lines: \(output.content.split(separator: "\n").count)")

                    // Check for common issues
                    if output.content.count < 100 {
                        DebugLogger.debug("   ⚠️ Very short response - may be incomplete")
                    }
                    if output.content.contains("I cannot") || output.content.contains("I'm unable") {
                        DebugLogger.debug("   ⚠️ Response contains refusal - check prompt")
                    }
                    if output.content.contains("...") && output.content.count > 5000 {
                        DebugLogger.debug("   ⚠️ Response may be truncated")
                    }

                    DebugLogger.debug(String(repeating: "─", count: 80) + "\n")
                } else {
                    // Production mode - minimal output
                    DebugLogger.always("✓ Response received")
                }
                return .success(output.content)
            } catch {
                DebugLogger.always("[AppleProvider] Error: \(error)")
                return .failure(.configurationError("Foundation Models error: \(error.localizedDescription)"))
            }
        } else {
            DebugLogger.debug("OS version too old", prefix: "AppleProvider")
            return .failure(.unsupportedFeature("Foundation Models requires macOS 16.0 or iOS 18.0"))
        }
        #else
        DebugLogger.debug("Foundation Models not available in build", prefix: "AppleProvider")
        // Fallback to mock response for testing
        return .success("Mock PRD response - Foundation Models not available")
        #endif
    }
}