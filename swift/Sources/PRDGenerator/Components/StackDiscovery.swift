import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles technical stack discovery and validation
public final class StackDiscovery {
    private let provider: AIProvider
    private let interactionHandler: UserInteractionHandler

    public init(provider: AIProvider, interactionHandler: UserInteractionHandler) {
        self.provider = provider
        self.interactionHandler = interactionHandler
    }

    /// Discovers technical stack through interactive questioning
    public func discoverTechnicalStack(input: String, skipQuestions: Bool = false) async throws -> StackContext {
        // Detect current platform first
        let currentPlatform = PlatformValidator.Platform.current
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PlatformMessages.detectedPlatform, currentPlatform.name))

        // Start with platform-appropriate defaults
        let defaultStack = PlatformValidator.getDefaultStack(for: currentPlatform)

        var language = defaultStack.language
        var testFramework = defaultStack.testFramework
        var cicdPipeline = defaultStack.cicdPipeline
        var deployment = defaultStack.deployment
        var database = defaultStack.database
        var security = defaultStack.security
        var performance = defaultStack.performance
        var integrations = defaultStack.integrations

        // If skipQuestions is true, just return defaults with the input as context
        if skipQuestions {
            return StackContext(
                language: language,
                testFramework: testFramework,
                cicdPipeline: cicdPipeline,
                deployment: deployment,
                database: database,
                security: security,
                performance: performance,
                integrations: integrations,
                questions: "Tech stack inferred from codebase context in input"
            )
        }

        // Generate questions via AI
        let stackPrompt = PRDPrompts.stackDiscoveryPrompt
            .replacingOccurrences(of: "%%@", with: input)

        let stackQuestions = try await generateSection(input: "", prompt: stackPrompt)

        // Parse and ask the key questions
        let parsedQuestions = parseQuestions(from: stackQuestions)

        if !parsedQuestions.isEmpty {
            interactionHandler.showInfo(PRDDisplayConstants.UserInteraction.needTechnicalRequirements)

            // Ask critical questions interactively
            for question in parsedQuestions.prefix(5) { // Limit to top 5 questions
                // First check if we should ask this question
                let shouldAsk = await interactionHandler.askYesNo(
                    String(format: PRDDisplayConstants.UserInteraction.wouldYouAnswerQuestion, question)
                )

                if shouldAsk {
                    // Now process the answer based on question type
                    let answer = await askQuestionBasedOnType(
                        question: question,
                        language: &language,
                        testFramework: &testFramework,
                        database: &database,
                        deployment: &deployment,
                        cicdPipeline: &cicdPipeline,
                        security: &security,
                        performance: &performance,
                        integrations: &integrations
                    )

                    // If question wasn't categorized, ask it as a general question
                    if answer == nil {
                        _ = await interactionHandler.askQuestion(question.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                }
            }

            interactionHandler.showInfo(PRDDisplayConstants.UserInteraction.thankYouValidating)
        }

        // Create the stack context
        let stack = StackContext(
            language: language,
            testFramework: testFramework,
            cicdPipeline: cicdPipeline,
            deployment: deployment,
            database: database,
            security: security,
            performance: performance,
            integrations: integrations,
            questions: stackQuestions
        )

        // Validate and potentially fix platform compatibility
        return try await validateAndFixCompatibility(stack: stack, currentPlatform: currentPlatform)
    }

    // MARK: - Private Methods

    private func askQuestionBasedOnType(
        question: String,
        language: inout String,
        testFramework: inout String?,
        database: inout String?,
        deployment: inout String?,
        cicdPipeline: inout String?,
        security: inout String?,
        performance: inout String?,
        integrations: inout [String]
    ) async -> Bool? {
        let lowerQuestion = question.lowercased()

        if PRDAnalysisConstants.QuestionCategories.language.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { language = answer }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.testing.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { testFramework = answer }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.database.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { database = answer }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.deployment.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty {
                if lowerQuestion.contains("deploy") {
                    deployment = answer
                } else if lowerQuestion.contains("pipeline") || lowerQuestion.contains("ci") || lowerQuestion.contains("cd") {
                    cicdPipeline = answer
                }
            }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.security.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { security = answer }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.performance.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { performance = answer }
            return true
        } else if PRDAnalysisConstants.QuestionCategories.integration.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty {
                // Add to integrations array if it's a list
                if answer.contains(",") {
                    integrations = answer.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                } else {
                    integrations.append(answer)
                }
            }
            return true
        }

        return nil
    }

    private func validateAndFixCompatibility(
        stack: StackContext,
        currentPlatform: PlatformValidator.Platform
    ) async throws -> StackContext {
        let validation = PlatformValidator.validateStack(stack)

        if !validation.isValid {
            interactionHandler.showWarning(PRDDisplayConstants.PlatformMessages.compatibilityIssues)
            interactionHandler.showWarning(validation.summary)

            let shouldFix = await interactionHandler.askYesNo(PRDDisplayConstants.UserInteraction.wouldYouFixCompatibility)

            if shouldFix {
                // Return platform-appropriate defaults
                let fixedStack = PlatformValidator.getDefaultStack(for: currentPlatform)
                interactionHandler.showInfo(
                    String(format: PRDDisplayConstants.PlatformMessages.usingCompatibleStack, currentPlatform.name)
                )
                return fixedStack
            } else {
                interactionHandler.showInfo(PRDDisplayConstants.PlatformMessages.proceedingWithWarning)
            }
        } else {
            interactionHandler.showInfo(String(format: PRDDisplayConstants.PlatformMessages.stackValidated, currentPlatform.name))
        }

        return stack
    }

    private func parseQuestions(from text: String) -> [String] {
        let lines = text.split(separator: "\n")
        var questions: [String] = []

        for line in lines {
            let cleanLine = String(line).trimmingCharacters(in: .whitespacesAndNewlines)

            if isQuestion(cleanLine) {
                var question = cleanLine
                // Remove numbering if present
                if let dotRange = question.range(of: ". ") {
                    question = String(question[dotRange.upperBound...])
                }
                questions.append(question)
            }
        }

        return questions
    }

    private func isQuestion(_ line: String) -> Bool {
        let lowerLine = line.lowercased()

        return line.contains("?") ||
               lowerLine.hasPrefix("what") ||
               lowerLine.hasPrefix("which") ||
               lowerLine.hasPrefix("how") ||
               lowerLine.hasPrefix("should") ||
               lowerLine.hasPrefix("will") ||
               ["1.", "2.", "3.", "4.", "5."].contains(where: { line.hasPrefix($0) })
    }

    private func generateSection(input: String, prompt: String) async throws -> String {
        let formattedPrompt = prompt.replacingOccurrences(
            of: "%%@",
            with: input
        )

        // For stack discovery, we don't want the full PRD system prompt
        // Just use the specific stack discovery prompt directly
        let messages = [
            ChatMessage(role: .user, content: formattedPrompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            interactionHandler.showWarning(String(format: PRDDisplayConstants.ErrorMessages.generationError, error.localizedDescription))
            throw error
        }
    }
}