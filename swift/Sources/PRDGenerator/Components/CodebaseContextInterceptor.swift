import Foundation

/// Intercepts technical stack questions and attempts to answer them from codebase context
/// before falling back to user interaction
public final class CodebaseContextInterceptor {

    /// Context from linked codebase
    public struct CodebaseContext {
        public let languages: [String: Int]  // {"Swift": 495054, "PLpgSQL": 34724}
        public let frameworks: [String]
        public let architecturePatterns: [String]
        public let repositoryUrl: String
        public let repositoryBranch: String

        public init(
            languages: [String: Int],
            frameworks: [String],
            architecturePatterns: [String],
            repositoryUrl: String,
            repositoryBranch: String
        ) {
            self.languages = languages
            self.frameworks = frameworks
            self.architecturePatterns = architecturePatterns
            self.repositoryUrl = repositoryUrl
            self.repositoryBranch = repositoryBranch
        }
    }

    private let codebaseContext: CodebaseContext?

    public init(codebaseContext: CodebaseContext?) {
        self.codebaseContext = codebaseContext
    }

    /// Attempts to answer a question from codebase context
    /// Returns the answer if found, nil if the question should be asked to the user
    public func tryAnswerFromCodebase(question: String) -> String? {
        guard let context = codebaseContext else {
            return nil
        }

        let lowerQuestion = question.lowercased()

        // Language questions
        if lowerQuestion.contains("programming language") ||
           lowerQuestion.contains("languages") ||
           lowerQuestion.contains("which language") {

            if !context.languages.isEmpty {
                let primaryLanguages = context.languages
                    .sorted { $0.value > $1.value }
                    .prefix(3)
                    .map { $0.key }
                    .joined(separator: ", ")

                return "Based on codebase analysis of \(context.repositoryUrl): \(primaryLanguages)"
            }
        }

        // Framework questions
        if lowerQuestion.contains("framework") ||
           lowerQuestion.contains("libraries") ||
           lowerQuestion.contains("dependencies") {

            if !context.frameworks.isEmpty {
                let frameworks = context.frameworks.prefix(5).joined(separator: ", ")
                return "Based on codebase analysis: \(frameworks)"
            } else {
                // Even if no frameworks detected, we can still provide info
                return "Based on codebase analysis: No major frameworks explicitly detected. Using standard library and platform APIs."
            }
        }

        // Architecture pattern questions
        if lowerQuestion.contains("architecture") ||
           lowerQuestion.contains("design pattern") ||
           lowerQuestion.contains("code structure") {

            if !context.architecturePatterns.isEmpty {
                let patterns = context.architecturePatterns.joined(separator: ", ")
                return "Based on codebase analysis: \(patterns)"
            } else {
                // Infer from languages
                if context.languages.keys.contains("Swift") {
                    return "Based on codebase analysis: Likely using MVC, MVVM, or Clean Architecture (common in Swift projects)"
                }
            }
        }

        // Testing framework questions
        if lowerQuestion.contains("testing framework") ||
           lowerQuestion.contains("test framework") ||
           lowerQuestion.contains("how to test") {

            // Infer from language
            if context.languages.keys.contains("Swift") {
                return "Based on codebase language (Swift): XCTest is the standard testing framework"
            } else if context.languages.keys.contains("TypeScript") || context.languages.keys.contains("JavaScript") {
                return "Based on codebase language (TypeScript/JavaScript): Jest or Vitest are common choices"
            } else if context.languages.keys.contains("Python") {
                return "Based on codebase language (Python): pytest or unittest"
            } else if context.languages.keys.contains("Go") {
                return "Based on codebase language (Go): testing package (built-in)"
            }
        }

        // Database questions
        if lowerQuestion.contains("database") ||
           lowerQuestion.contains("data storage") ||
           lowerQuestion.contains("persistence") {

            // Check for database-related languages/frameworks
            if context.languages.keys.contains("PLpgSQL") || context.languages.keys.contains("SQL") {
                return "Based on codebase analysis: PostgreSQL (detected PLpgSQL code)"
            } else if context.frameworks.contains(where: { $0.lowercased().contains("mongodb") }) {
                return "Based on codebase analysis: MongoDB"
            } else if context.frameworks.contains(where: { $0.lowercased().contains("sqlite") }) {
                return "Based on codebase analysis: SQLite"
            }
        }

        // CI/CD and deployment questions
        if lowerQuestion.contains("ci/cd") ||
           lowerQuestion.contains("continuous integration") ||
           lowerQuestion.contains("pipeline") {

            // Could check for .github/workflows, .gitlab-ci.yml, etc.
            // For now, provide default based on repo
            if context.repositoryUrl.contains("github.com") {
                return "Recommended: GitHub Actions (repository is hosted on GitHub)"
            }
        }

        // Security questions
        if lowerQuestion.contains("security") ||
           lowerQuestion.contains("authentication") ||
           lowerQuestion.contains("authorization") {

            // Check frameworks for auth-related ones
            if context.frameworks.contains(where: { $0.lowercased().contains("jwt") }) {
                return "Based on codebase: JWT-based authentication detected"
            } else if context.frameworks.contains(where: { $0.lowercased().contains("oauth") }) {
                return "Based on codebase: OAuth authentication detected"
            }
        }

        return nil  // Cannot answer from codebase, ask user
    }

    /// Checks if a question is answerable from codebase context
    public func canAnswerFromCodebase(question: String) -> Bool {
        return tryAnswerFromCodebase(question: question) != nil
    }

    /// Get summary of what the codebase context provides
    public func getCodebaseSummary() -> String? {
        guard let context = codebaseContext else {
            return nil
        }

        var summary = "📊 Codebase Analysis from \(context.repositoryUrl) (branch: \(context.repositoryBranch)):\n"

        if !context.languages.isEmpty {
            let languages = context.languages
                .sorted { $0.value > $1.value }
                .map { "\($0.key) (\($0.value) bytes)" }
                .joined(separator: ", ")
            summary += "  • Languages: \(languages)\n"
        }

        if !context.frameworks.isEmpty {
            summary += "  • Frameworks: \(context.frameworks.joined(separator: ", "))\n"
        }

        if !context.architecturePatterns.isEmpty {
            summary += "  • Architecture: \(context.architecturePatterns.joined(separator: ", "))\n"
        }

        return summary
    }
}
