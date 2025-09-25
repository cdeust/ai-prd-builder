import Foundation
import CommonModels
import DomainCore

/// Processes mockup files and extracts requirements for PRD generation
public final class MockupProcessor {
    private let provider: AIProvider
    private let configuration: Configuration

    public init(provider: AIProvider, configuration: Configuration) {
        self.provider = provider
        self.configuration = configuration
    }

    /// Process mockup files with optional guidelines
    public func processMockups(
        paths: [String],
        guidelines: String? = nil,
        context: String? = nil
    ) async throws -> String {
        guard !paths.isEmpty else {
            return ""
        }

        let mockupPrompt = PRDPrompts.buildMockupAnalysisPrompt(
            paths: paths,
            guidelines: guidelines,
            context: context
        )

        let messages = [
            ChatMessage(
                role: .system,
                content: PRDPrompts.mockupSystemRolePrompt
            ),
            ChatMessage(
                role: .user,
                content: mockupPrompt
            )
        ]

        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let content):
            response = content
        case .failure(let error):
            throw error
        }

        return MockupConstants.formatAnalysisResult(
            content: response,
            paths: paths
        )
    }
}

// MARK: - Constants

private enum MockupConstants {
    enum Config {
        static let temperature: Double = 0.3
        static let maxTokens: Int = 2000
    }

    enum Formatting {
        static let sectionTitle = PRDContextConstants.DesignGuidelines.mockupSectionTitle
        static let filesHeader = PRDContextConstants.DesignGuidelines.referencedFilesHeader
        static let filePrefix = "- `"
        static let fileSuffix = "`"
        static let sectionSeparator = PRDDataConstants.Separators.doubleNewline
        static let listSeparator = PRDDataConstants.Separators.newline
    }

    static func formatAnalysisResult(content: String, paths: [String]) -> String {
        """
        \(Formatting.sectionTitle)

        \(content)

        \(Formatting.filesHeader)
        \(paths.map { "\(Formatting.filePrefix)\($0)\(Formatting.fileSuffix)" }.joined(separator: Formatting.listSeparator))
        """
    }
}