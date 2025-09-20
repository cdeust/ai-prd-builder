import Foundation
import CommonModels
import DomainCore

/// Analyzes initial requirements and technical stack, collecting all necessary clarifications upfront
public final class RequirementsAnalyzer {
    // Composed components
    private let analysisOrchestrator: AnalysisOrchestrator
    private let confidenceEvaluator: ConfidenceEvaluator
    private let clarificationCollector: ClarificationCollector
    private let requirementsEnricher: RequirementsEnricher
    private let interactionHandler: UserInteractionHandler

    public init(
        provider: AIProvider,
        interactionHandler: UserInteractionHandler
    ) {
        self.analysisOrchestrator = AnalysisOrchestrator(provider: provider)
        self.confidenceEvaluator = ConfidenceEvaluator()
        self.clarificationCollector = ClarificationCollector(interactionHandler: interactionHandler)
        self.requirementsEnricher = RequirementsEnricher()
        self.interactionHandler = interactionHandler
    }

    /// Analyzes the input, technical stack, and collects all clarifications before generation starts
    public func analyzeAndClarify(input: String) async throws -> EnrichedRequirements {
        print(PRDConstants.AnalysisMessages.analyzingCompleteness)

        // Step 1: Perform parallel analysis of requirements and stack
        async let requirementsTask = analysisOrchestrator.analyzeRequirements(input: input)
        async let stackTask = analysisOrchestrator.analyzeTechnicalStack(input: input)

        let analysis = try await requirementsTask
        let stackAnalysis = try await stackTask

        // Step 2: Check if confidence is too low to proceed
        if confidenceEvaluator.isBelowMinimumViability(analysis.confidence) {
            return try await handleVeryLowConfidence(input: input, analysis: analysis, stackAnalysis: stackAnalysis)
        }

        // Step 3: Filter based on confidence levels
        let filteredAnalysis = confidenceEvaluator.filterByConfidence(analysis)
        let filteredStackAnalysis = confidenceEvaluator.filterByConfidence(stackAnalysis)

        // Step 4: Determine if clarifications should be collected
        var enrichedInput = input
        var allClarifications: [String: String] = [:]

        let shouldAskClarifications = shouldCollectClarifications(
            filteredAnalysis: filteredAnalysis,
            filteredStackAnalysis: filteredStackAnalysis
        )

        if shouldAskClarifications {
            // Present clarifications and get approval
            let shouldClarify = await clarificationCollector.presentClarificationsForApproval(
                requirementsClarifications: filteredAnalysis.clarificationsNeeded,
                stackClarifications: filteredStackAnalysis.clarificationsNeeded,
                requirementsConfidence: analysis.confidence,
                stackConfidence: stackAnalysis.confidence
            )

            if shouldClarify {
                let (requirementsClarifications, stackClarifications) =
                    await clarificationCollector.collectBatchedClarifications(
                        requirementsClarifications: filteredAnalysis.clarificationsNeeded,
                        stackClarifications: filteredStackAnalysis.clarificationsNeeded
                    )

                // Merge all clarifications
                allClarifications = requirementsEnricher.mergeClarifications([
                    requirementsClarifications,
                    stackClarifications
                ])

                // Build enriched input
                enrichedInput = requirementsEnricher.enrichInput(
                    original: input,
                    requirementsClarifications: requirementsClarifications,
                    stackClarifications: stackClarifications,
                    assumptions: filteredAnalysis.assumptions,
                    stackAssumptions: filteredStackAnalysis.assumptions
                )

                // Re-analyze if needed
                if needsReanalysis(analysis, stackAnalysis) {
                    try await performReanalysis(
                        enrichedInput: enrichedInput,
                        originalAnalysis: analysis
                    )
                }
            }
        }

        // Build final result
        let overallConfidence = confidenceEvaluator.calculateOverallConfidence(
            requirementsConfidence: analysis.confidence,
            stackConfidence: stackAnalysis.confidence,
            clarificationsProvided: !allClarifications.isEmpty
        )

        return EnrichedRequirements(
            originalInput: input,
            enrichedInput: enrichedInput,
            clarifications: allClarifications,
            assumptions: filteredAnalysis.assumptions + filteredStackAnalysis.assumptions,
            gaps: filteredAnalysis.gaps + filteredStackAnalysis.gaps,
            initialConfidence: overallConfidence,
            stackClarifications: [:] // Merged into main clarifications
        )
    }

    // MARK: - Private Methods

    private func shouldCollectClarifications(
        filteredAnalysis: RequirementsAnalysis,
        filteredStackAnalysis: RequirementsAnalysis
    ) -> Bool {
        return confidenceEvaluator.needsClarification(filteredAnalysis.confidence) ||
               confidenceEvaluator.needsClarification(filteredStackAnalysis.confidence) ||
               !filteredAnalysis.clarificationsNeeded.isEmpty ||
               !filteredStackAnalysis.clarificationsNeeded.isEmpty
    }

    private func needsReanalysis(
        _ analysis: RequirementsAnalysis,
        _ stackAnalysis: RequirementsAnalysis
    ) -> Bool {
        return confidenceEvaluator.needsRefinement(analysis.confidence) ||
               confidenceEvaluator.needsRefinement(stackAnalysis.confidence)
    }

    private func performReanalysis(
        enrichedInput: String,
        originalAnalysis: RequirementsAnalysis
    ) async throws {
        print(PRDConstants.AnalysisMessages.reanalyzing)

        let refinedAnalysis = try await analysisOrchestrator.reanalyzeWithContext(
            enrichedInput: enrichedInput
        )

        if refinedAnalysis.confidence > originalAnalysis.confidence {
            print(String(format: PRDConstants.AnalysisMessages.confidenceImproved,
                        originalAnalysis.confidence, refinedAnalysis.confidence))
        }
    }

    private func handleVeryLowConfidence(
        input: String,
        analysis: RequirementsAnalysis,
        stackAnalysis: RequirementsAnalysis
    ) async throws -> EnrichedRequirements {
        interactionHandler.showInfo(
            String(format: PRDConstants.AnalysisMessages.confidenceTooLow, analysis.confidence)
        )

        // Collect essential clarifications
        let essentialResponses = await clarificationCollector.collectEssentialClarifications()

        // Enrich input with essentials
        let enrichedInput = requirementsEnricher.enrichWithEssentials(
            original: input,
            essentialResponses: essentialResponses
        )

        // Re-analyze with essential information
        print(PRDConstants.AnalysisMessages.reanalyzing)
        let improvedAnalysis = try await analysisOrchestrator.reanalyzeWithContext(
            enrichedInput: enrichedInput
        )

        print(String(format: PRDConstants.AnalysisMessages.confidenceImproved,
                    analysis.confidence, improvedAnalysis.confidence))

        return EnrichedRequirements(
            originalInput: input,
            enrichedInput: enrichedInput,
            clarifications: essentialResponses,
            assumptions: improvedAnalysis.assumptions,
            gaps: improvedAnalysis.gaps,
            initialConfidence: improvedAnalysis.confidence,
            stackClarifications: [:]
        )
    }
}