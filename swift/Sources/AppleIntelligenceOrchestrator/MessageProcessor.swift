import Foundation
import AIBridge
import AIProviders

/// Processes chat messages with thinking mode support
public struct MessageProcessor {
    let orchestrator: Orchestrator
    let thinkingMode: Orchestrator.ThinkingMode

    public init(orchestrator: Orchestrator, thinkingMode: Orchestrator.ThinkingMode) {
        self.orchestrator = orchestrator
        self.thinkingMode = thinkingMode
    }

    public func process(_ message: String) async throws {
        displayThinkingModeIfNeeded()

        let options = ChatOptions(
            injectContext: true,
            useRefinement: false
        )

        let result = try await executeChat(
            message: message,
            options: options
        )

        displayResult(result)
    }

    private func displayThinkingModeIfNeeded() {
        if thinkingMode != .automatic && thinkingMode != .chainOfThought {
            print("\(CommandConstants.Messages.thinkingPrefix)\(thinkingMode.rawValue)\(CommandConstants.Messages.thinkingSuffix)")
        }
    }

    private func executeChat(
        message: String,
        options: ChatOptions
    ) async throws -> ChatResult {

        AppleIntelligenceOrchestrator.showProcessingStatus(CommandConstants.Messages.processingMessage)

        let startTime = Date()
        let (response, provider) = try await orchestrator.chat(
            message: message,
            useAppleIntelligence: true,
            options: options,
            thinkingMode: thinkingMode
        )
        let elapsed = Date().timeIntervalSince(startTime)

        return ChatResult(
            response: response,
            provider: provider,
            elapsed: elapsed
        )
    }

    private func displayResult(_ result: ChatResult) {
        if result.elapsed > CommandConstants.Thresholds.longResponseTime {
            print(String(format: CommandConstants.Format.elapsedTime, result.elapsed))
        }

        print(String(format: CommandConstants.Format.providerResponse, result.provider.rawValue, result.response))
    }
}

/// Result of a chat message processing
public struct ChatResult {
    public let response: String
    public let provider: Orchestrator.AIProvider
    public let elapsed: TimeInterval

    public init(response: String, provider: Orchestrator.AIProvider, elapsed: TimeInterval) {
        self.response = response
        self.provider = provider
        self.elapsed = elapsed
    }
}