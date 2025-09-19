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

                print("[AppleProvider] Prompt size: \(promptText.count) characters")

                // Extract system instruction if present
                let systemInstruction = messages.first(where: { $0.role == .system })?.content ?? ""

                // Create session and generate response
                print("[AppleProvider] Creating session...")
                let session = LanguageModelSession(instructions: systemInstruction)

                print("[AppleProvider] Sending request to model...")
                let output = try await session.respond(to: promptText)

                print("[AppleProvider] Received response: \(output.content.prefix(100))...")
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