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
    public func discoverTechnicalStack(input: String) async throws -> StackContext {
        // Detect current platform first
        let currentPlatform = PlatformValidator.Platform.current
        print(String(format: PRDConstants.Messages.detectedPlatform, currentPlatform.name))

        let stackPrompt = PRDPrompts.stackDiscoveryPrompt
            .replacingOccurrences(of: PRDConstants.PromptReplacements.placeholder, with: input)

        let stackQuestions = try await generateSection(input: "", prompt: stackPrompt)

        // Parse and ask the key questions
        let parsedQuestions = parseQuestions(from: stackQuestions)

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

        if !parsedQuestions.isEmpty {
            interactionHandler.showInfo(PRDConstants.Messages.needTechnicalRequirements)

            // Ask critical questions interactively
            for question in parsedQuestions.prefix(5) { // Limit to top 5 questions
                // First check if we should ask this question
                let shouldAsk = await interactionHandler.askYesNo(
                    String(format: PRDConstants.Messages.wouldYouAnswerQuestion, question)
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
                        _ = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }

            interactionHandler.showInfo(PRDConstants.Messages.thankYouValidating)
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

        if PRDConstants.QuestionParsing.languageKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { language = answer }
            return true
        } else if PRDConstants.QuestionParsing.testKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { testFramework = answer }
            return true
        } else if PRDConstants.QuestionParsing.databaseKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { database = answer }
            return true
        } else if PRDConstants.QuestionParsing.deployKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty {
                if lowerQuestion.contains("deploy") {
                    deployment = answer
                } else if lowerQuestion.contains("pipeline") || lowerQuestion.contains("ci") || lowerQuestion.contains("cd") {
                    cicdPipeline = answer
                }
            }
            return true
        } else if PRDConstants.QuestionParsing.securityKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { security = answer }
            return true
        } else if PRDConstants.QuestionParsing.performanceKeywords.contains(where: { lowerQuestion.contains($0) }) {
            let answer = await interactionHandler.askQuestion(question.trimmingCharacters(in: .whitespacesAndNewlines))
            if !answer.isEmpty { performance = answer }
            return true
        } else if PRDConstants.QuestionParsing.integrationKeywords.contains(where: { lowerQuestion.contains($0) }) {
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
            print(PRDConstants.Messages.compatibilityIssues)
            print(validation.summary)

            let shouldFix = await interactionHandler.askYesNo(PRDConstants.Messages.wouldYouFixCompatibility)

            if shouldFix {
                // Return platform-appropriate defaults
                let fixedStack = PlatformValidator.getDefaultStack(for: currentPlatform)
                interactionHandler.showInfo(
                    String(format: PRDConstants.Messages.usingCompatibleStack, currentPlatform.name)
                )
                return fixedStack
            } else {
                interactionHandler.showInfo(PRDConstants.Messages.proceedingWithWarning)
            }
        } else {
            print(String(format: PRDConstants.Messages.stackValidated, currentPlatform.name))
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
                if let dotRange = question.range(of: PRDConstants.QuestionParsing.dotSpace) {
                    question = String(question[dotRange.upperBound...])
                }
                questions.append(question)
            }
        }

        return questions
    }

    private func isQuestion(_ line: String) -> Bool {
        let lowerLine = line.lowercased()

        return line.contains(PRDConstants.QuestionParsing.questionMark) ||
               lowerLine.hasPrefix(PRDConstants.QuestionParsing.what) ||
               lowerLine.hasPrefix(PRDConstants.QuestionParsing.which) ||
               lowerLine.hasPrefix(PRDConstants.QuestionParsing.how) ||
               lowerLine.hasPrefix(PRDConstants.QuestionParsing.should) ||
               lowerLine.hasPrefix(PRDConstants.QuestionParsing.will) ||
               PRDConstants.QuestionParsing.numberPrefixes.contains(where: { line.hasPrefix($0) })
    }

    private func generateSection(input: String, prompt: String) async throws -> String {
        let formattedPrompt = prompt.replacingOccurrences(
            of: PRDConstants.PromptReplacements.placeholder,
            with: input
        )

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: formattedPrompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            print(String(format: PRDConstants.Messages.generationError, error.localizedDescription))
            throw error
        }
    }
}