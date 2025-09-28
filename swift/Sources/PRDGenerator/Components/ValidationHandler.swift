import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles response validation and improvement
public final class ValidationHandler {
    private let provider: AIProvider
    private let assumptionTracker: AssumptionTracker
    private let interactionHandler: UserInteractionHandler
    private let sectionGenerator: SectionGeneratorProtocol
    private let alternativeGenerator: AlternativeGenerator
    private let configuration: Configuration

    public init(
        provider: AIProvider,
        assumptionTracker: AssumptionTracker,
        interactionHandler: UserInteractionHandler,
        sectionGenerator: SectionGeneratorProtocol,
        configuration: Configuration = Configuration()
    ) {
        self.provider = provider
        self.assumptionTracker = assumptionTracker
        self.interactionHandler = interactionHandler
        self.sectionGenerator = sectionGenerator
        self.alternativeGenerator = AlternativeGenerator(provider: provider)
        self.configuration = configuration
    }

    /// Generates content with validation and optional user interaction
    public func generateWithValidation(
        input: String,
        prompt: String,
        sectionName: String
    ) async throws -> ValidatedResponse {
        // Show which section we're generating
        interactionHandler.showProgress(String(format: PRDDisplayConstants.ProgressMessages.generatingSectionFormat, sectionName))

        // Initial generation
        let initialResponse = try await sectionGenerator.generateSection(input: input, prompt: prompt)

        // Emit the actual generated content for streaming
        interactionHandler.showSectionContent(initialResponse)

        // Extract and track assumptions
        let assumptions = try await assumptionTracker.extractAssumptions(from: initialResponse)
        interactionHandler.showInfo(String(format: PRDAnalysisConstants.AnalysisMessages.foundAssumptions, assumptions.count))

        // Validate the response
        let validation = try await validateResponse(input: input, response: initialResponse)

        // Check if confidence is too low to proceed
        if validation.confidence < PRDDataConstants.Confidence.minimum {
            interactionHandler.showWarning(
                "Confidence too low (\(validation.confidence)%) for section: \(sectionName). " +
                "This section needs significant clarification."
            )
            // Force user clarification for very low confidence
            return try await handleUserClarification(
                prompt: prompt,
                input: input,
                validation: validation,
                assumptions: assumptions
            )
        }

        // Handle low confidence that needs improvement
        if validation.confidence < PRDDataConstants.Confidence.low {
            return try await handleLowConfidence(
                validation: validation,
                sectionName: sectionName,
                input: input,
                prompt: prompt,
                initialResponse: initialResponse,
                assumptions: assumptions
            )
        }

        // Since clarifications are now collected upfront, we don't need to ask here
        // Just include them in the response for transparency

        return ValidatedResponse(
            content: initialResponse,
            confidence: validation.confidence,
            assumptions: assumptions.map { $0.statement },
            clarificationsNeeded: validation.clarificationsNeeded
        )
    }

    // MARK: - Private Methods

    private func validateResponse(input: String, response: String) async throws -> ValidationInfo {
        let validationPrompt = PRDPrompts.responseValidationPrompt
            .replacingOccurrences(of: "%%@", with: input)
            .replacingOccurrences(of: "%%@", with: response)

        let validationResult = try await sectionGenerator.generateSection(input: "", prompt: validationPrompt)
        return parseValidationResult(validationResult)
    }

    private func handleLowConfidence(
        validation: ValidationInfo,
        sectionName: String,
        input: String,
        prompt: String,
        initialResponse: String,
        assumptions: [TrackedAssumption]
    ) async throws -> ValidatedResponse {
        interactionHandler.showInfo(
            String(format: PRDAnalysisConstants.AnalysisMessages.lowConfidenceFormat, validation.confidence, sectionName)
        )

        // Show missing information
        if !validation.gaps.isEmpty {
            interactionHandler.showInfo(PRDAnalysisConstants.AnalysisMessages.missingInfoHeader)
            for gap in validation.gaps.prefix(3) {
                interactionHandler.showInfo(String(format: PRDAnalysisConstants.AnalysisMessages.missingInfoItem, gap))
            }
        }

        // Ask user for clarification
        let shouldClarify = await interactionHandler.askYesNo(PRDDisplayConstants.UserInteraction.wouldYouProvideDetails)

        if shouldClarify {
            return try await handleUserClarification(
                prompt: prompt,
                input: input,
                validation: validation,
                assumptions: assumptions
            )
        } else {
            return try await handleAutomaticImprovement(
                initialResponse: initialResponse,
                validation: validation,
                input: input,
                assumptions: assumptions
            )
        }
    }

    private func handleUserClarification(
        prompt: String,
        input: String,
        validation: ValidationInfo,
        assumptions: [TrackedAssumption]
    ) async throws -> ValidatedResponse {
        let additionalDetails = await interactionHandler.askQuestion(PRDDisplayConstants.UserInteraction.provideAdditionalContext)

        // Regenerate with additional context
        let enhancedPrompt = prompt + PRDContextConstants.ContentFormatting.additionalContextPrefix + additionalDetails
        let improvedResponse = try await sectionGenerator.generateSection(input: input, prompt: enhancedPrompt)

        // Emit the improved content for streaming
        interactionHandler.showSectionContent(improvedResponse)

        return ValidatedResponse(
            content: improvedResponse,
            confidence: min(validation.confidence + 25, 95),
            assumptions: assumptions.map { $0.statement },
            clarificationsNeeded: [] // Clarifications addressed
        )
    }

    private func handleAutomaticImprovement(
        initialResponse: String,
        validation: ValidationInfo,
        input: String,
        assumptions: [TrackedAssumption]
    ) async throws -> ValidatedResponse {
        // Generate alternatives when confidence is very low
        if validation.confidence < 50 {
            interactionHandler.showProgress("Generating alternative approaches...")

            let alternatives = try await alternativeGenerator.generateAlternatives(
                for: initialResponse,
                context: input,
                confidence: validation.confidence
            )

            if !alternatives.isEmpty {
                // Show alternatives to user
                interactionHandler.showInfo("\nFound \(alternatives.count) alternative approaches:")
                for (index, alt) in alternatives.enumerated() {
                    interactionHandler.showInfo("\n--- Alternative \(index + 1) ---")
                    interactionHandler.showInfo(alt.formattedDescription)
                }

                // Select best alternative
                if let bestAlternative = alternativeGenerator.selectBestAlternative(from: alternatives) {
                    interactionHandler.showInfo("\n✨ Using best alternative: \(bestAlternative.description)")
                    return ValidatedResponse(
                        content: bestAlternative.description,
                        confidence: Int(bestAlternative.probabilityOfSuccess * 100),
                        assumptions: assumptions.map { $0.statement },
                        clarificationsNeeded: validation.clarificationsNeeded
                    )
                }
            }
        }

        // Fallback to original challenge and improve
        let challengedResponse = try await challengeAndImprove(
            originalResponse: initialResponse,
            validation: validation,
            input: input
        )

        // Emit the challenged/improved content for streaming
        interactionHandler.showSectionContent(challengedResponse)

        return ValidatedResponse(
            content: challengedResponse,
            confidence: min(validation.confidence + 15, 90),
            assumptions: assumptions.map { $0.statement },
            clarificationsNeeded: validation.clarificationsNeeded
        )
    }

    private func challengeAndImprove(
        originalResponse: String,
        validation: ValidationInfo,
        input: String
    ) async throws -> String {
        let challengePrompt = PRDPrompts.challengeResponsePrompt
            .replacingOccurrences(of: "%%@", with: originalResponse)
            .replacingOccurrences(of: "%%@", with: "\(validation)")

        return try await sectionGenerator.generateSection(input: input, prompt: challengePrompt)
    }

    private func parseValidationResult(_ jsonString: String) -> ValidationInfo {
        // Extract JSON from the response
        guard let jsonStart = jsonString.range(of: PRDDataConstants.RegexPatterns.jsonCodeBlockStart),
              let jsonEnd = jsonString.range(of: PRDDataConstants.RegexPatterns.jsonCodeBlockEnd,
                                            range: jsonStart.upperBound..<jsonString.endIndex) else {
            // Fallback if no JSON found
            return ValidationInfo(
                confidence: PRDDataConstants.Defaults.defaultConfidence,
                assumptions: [],
                gaps: [],
                recommendations: [],
                clarificationsNeeded: []
            )
        }

        let jsonContent = String(jsonString[jsonStart.upperBound..<jsonEnd.lowerBound])
        guard let data = jsonContent.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ValidationInfo(
                confidence: PRDDataConstants.Defaults.defaultConfidence,
                assumptions: [],
                gaps: [],
                recommendations: [],
                clarificationsNeeded: []
            )
        }

        return ValidationInfo(
            confidence: json[PRDDataConstants.JSONKeys.confidence] as? Int ?? PRDDataConstants.Defaults.defaultConfidence,
            assumptions: json[PRDDataConstants.JSONKeys.assumptions] as? [String] ?? [],
            gaps: json[PRDDataConstants.JSONKeys.gaps] as? [String] ?? [],
            recommendations: json[PRDDataConstants.JSONKeys.recommendations] as? [String] ?? [],
            clarificationsNeeded: json["clarifications_needed"] as? [String] ?? []
        )
    }

    private func handleClarificationPrompts(
        clarifications: [String],
        sectionName: String
    ) async -> Bool {
        // This method is now deprecated since clarifications are collected upfront
        // Kept for backward compatibility but always returns false
        return false
    }
}

/// Protocol for section generation
public protocol SectionGeneratorProtocol {
    func generateSection(input: String, prompt: String) async throws -> String
}