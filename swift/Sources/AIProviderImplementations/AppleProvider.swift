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
        print("[AppleProvider] Received \(messages.count) messages")

        #if canImport(FoundationModels)
        if #available(macOS 16.0, iOS 18.0, *) {
            do {
                print("[AppleProvider] Using Foundation Models...")
                // Use SystemLanguageModel
                let model = SystemLanguageModel.default

                // Check availability
                guard model.isAvailable else {
                    print("[AppleProvider] Model not available")
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
                print("\n📤 Processing request (\(promptText.count) chars)...")

                // Extract system instruction if present
                let systemInstruction = messages.first(where: { $0.role == .system })?.content ?? ""

                // Create session and generate response
                let session = LanguageModelSession(instructions: systemInstruction)
                let output = try await session.respond(to: promptText)

                // Show full response for debugging (always in debug mode)
                if showDebugOutput {
                    print("\n" + String(repeating: "─", count: 80))
                    print("📥 APPLE INTELLIGENCE RESPONSE:")
                    print(String(repeating: "─", count: 80))

                    // Show the complete response for analysis
                    print(output.content)

                    // Add summary info for quick understanding
                    print(String(repeating: "─", count: 80))
                    print("📊 Response Stats:")
                    print("   • Length: \(output.content.count) characters")
                    print("   • Lines: \(output.content.split(separator: "\n").count)")

                    // Check for common issues
                    if output.content.count < 100 {
                        print("   ⚠️ Very short response - may be incomplete")
                    }
                    if output.content.contains("I cannot") || output.content.contains("I'm unable") {
                        print("   ⚠️ Response contains refusal - check prompt")
                    }
                    if output.content.contains("...") && output.content.count > 5000 {
                        print("   ⚠️ Response may be truncated")
                    }

                    print(String(repeating: "─", count: 80) + "\n")
                } else {
                    // Production mode - minimal output
                    print("✓ Response received")
                }
                return .success(output.content)
            } catch {
                print("[AppleProvider] Error: \(error)")
                return .failure(.configurationError("Foundation Models error: \(error.localizedDescription)"))
            }
        } else {
            print("[AppleProvider] OS version too old")
            return .failure(.unsupportedFeature("Foundation Models requires macOS 16.0 or iOS 18.0"))
        }
        #else
        print("[AppleProvider] Foundation Models not available in build")
        // Fallback to mock response for testing
        return .success("Mock PRD response - Foundation Models not available")
        #endif
    }
}