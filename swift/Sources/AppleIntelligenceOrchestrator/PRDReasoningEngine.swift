import Foundation
import AIBridge
import ThinkingFramework

/// Manages reasoning and thought processes for PRD generation
public struct PRDReasoningEngine {

    private let chainOfThought: ChainOfThought
    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.chainOfThought = ChainOfThought(orchestrator: orchestrator)
    }

    // MARK: - Public Interface

    /// Analyze requirements using iterative Chain of Thought until confident
    public func analyzeRequirements(_ input: String) async throws -> ThoughtChain {
        var bestChain: ThoughtChain?
        var previousConfidence: Float = OpenAPIPromptConstants.Confidence.minValue
        var previousConclusions: [String] = []
        var exploredApproaches: Set<String> = []

        for iteration in PRDGeneratorConstants.Iterations.firstIteration...PRDConstants.ReasoningEngine.maxIterations {
            print(String(format: PRDConstants.ReasoningEngine.iterationMessage,
                        iteration, PRDConstants.ReasoningEngine.maxIterations))

            // For first iterations, use self-consistency (2025 best practice)
            let useSelfConsistency = iteration <= ReasoningConstants.Iterations.selfConsistencyThreshold
            let numPaths = useSelfConsistency ? min(ReasoningConstants.Iterations.maxPaths, ReasoningConstants.Iterations.pathReductionFactor - iteration) : ReasoningConstants.Iterations.minPaths

            // Select approach based on what hasn't been explored yet
            let approach = selectUnexploredApproach(
                iteration: iteration,
                exploredApproaches: exploredApproaches
            )
            exploredApproaches.insert(approach)

            // Simplified problem statement (avoid over-engineering per 2025 research)
            let problem: String
            if iteration == PRDGeneratorConstants.Iterations.firstIteration {
                // Start simple with zero-shot
                problem = String(format: PRDConstants.ThinkingIntegration.problemTemplate, input)
            } else {
                // Build on previous insights without overcomplicating
                problem = buildSimplifiedIterativeProblem(
                    input: input,
                    iteration: iteration,
                    previousConfidence: previousConfidence,
                    bestPreviousConclusion: previousConclusions.last ?? "",
                    approach: approach
                )
            }

            // Use focused constraints only when necessary
            let constraints = iteration > ReasoningConstants.Iterations.constraintApplicationThreshold ? ReasoningConstants.Constraints.iterationConstraints : []

            let chain = try await chainOfThought.thinkThrough(
                problem: problem,
                context: PRDConstants.ThinkingIntegration.contextTemplate,
                constraints: constraints,
                useSelfConsistency: useSelfConsistency,
                numPaths: numPaths
            )

            // Enhance confidence calculation with actual evidence
            let enhancedConfidence = calculateEnhancedConfidence(
                chain: chain,
                iteration: iteration
            )

            // Create enhanced chain with calculated confidence
            let enhancedChain = ThoughtChain(
                id: chain.id,
                problem: chain.problem,
                thoughts: chain.thoughts,
                conclusion: chain.conclusion,
                confidence: enhancedConfidence,
                alternatives: chain.alternatives,
                assumptions: chain.assumptions,
                timestamp: chain.timestamp
            )

            print(String(format: PRDConstants.ReasoningEngine.confidenceMessage, enhancedChain.confidence))

            // Track conclusions for diversity
            previousConclusions.append(enhancedChain.conclusion)
            previousConfidence = enhancedChain.confidence

            // Keep the best chain so far
            if bestChain == nil || enhancedChain.confidence > bestChain!.confidence {
                bestChain = enhancedChain
            }

            // Stop if we have sufficient confidence
            if enhancedChain.confidence >= PRDConstants.ReasoningEngine.minConfidence {
                print(PRDConstants.ReasoningEngine.sufficientConfidenceMessage)
                break
            } else if iteration < PRDConstants.ReasoningEngine.maxIterations {
                print(PRDConstants.ReasoningEngine.lowConfidenceMessage)
                // Reset chain of thought for next iteration to avoid state accumulation
                chainOfThought.reset()
            }
        }

        guard let finalChain = bestChain else {
            throw PRDError.reasoningFailed(String(format: PRDConstants.ReasoningEngine.reasoningFailedError,
                                                  PRDConstants.ReasoningEngine.maxIterations))
        }

        return finalChain
    }

    /// Detect patterns in multiple PRD generations
    public func detectPatterns(in chains: [ThoughtChain]) -> [DetectedPattern] {
        return chainOfThought.detectPatterns(in: chains)
    }

    /// Generate reasoning-enhanced overview
    public func generateEnhancedOverview(
        input: String,
        thoughtChain: ThoughtChain?
    ) async throws -> String {
        let prompt: String

        if let chain = thoughtChain {
            prompt = String(format: PRDConstants.YAMLFormatting.enhancedOverviewPrompt,
                          input,
                          chain.conclusion,
                          chain.confidence)
        } else {
            // Fallback prompt without chain analysis
            prompt = String(format: PRDConstants.YAMLFormatting.enhancedOverviewPrompt,
                          input,
                          "No prior analysis available",
                          PRDGeneratorConstants.Assumptions.defaultConfidenceValue)
        }

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response
    }

    /// Validate reasoning consistency
    public func validateReasoningConsistency(
        thoughtChain: ThoughtChain,
        prdContent: String
    ) async throws -> Bool {
        let contentSummary = String(prdContent.prefix(PRDConstants.ThinkingIntegration.prdContentSummaryLength))
        let prompt = String(format: PRDConstants.YAMLFormatting.validationFormat,
                          thoughtChain.conclusion,
                          contentSummary)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .criticalAnalysis  // Use critical analysis for validation
        )

        return response.contains(PRDConstants.ThinkingIntegration.validationYes)
    }

    // MARK: - Private Helper Methods

    private func buildSimplifiedIterativeProblem(
        input: String,
        iteration: Int,
        previousConfidence: Float,
        bestPreviousConclusion: String,
        approach: String
    ) -> String {
        // 2025 best practice: Keep it simple, avoid over-instructing
        var problem = String(format: PRDConstants.ThinkingIntegration.problemTemplate, input)

        if previousConfidence < ReasoningConstants.Confidence.lowConfidenceThreshold {
            problem += String(format: ReasoningConstants.ProblemBuilding.lowConfidenceMessage, approach)
        } else if !bestPreviousConclusion.isEmpty {
            problem += ReasoningConstants.ProblemBuilding.buildingOnMessage + String(bestPreviousConclusion.prefix(ReasoningConstants.ProblemBuilding.conclusionPrefixLength))
            problem += String(format: ReasoningConstants.ProblemBuilding.approachMessage, approach)
        }

        // Natural progression without explicit instructions
        if iteration > ReasoningConstants.Iterations.exampleRequestThreshold {
            problem += ReasoningConstants.ProblemBuilding.stepByStepWithExamplesMessage
        } else {
            problem += ReasoningConstants.ProblemBuilding.stepByStepMessage
        }

        return problem
    }

    private func selectUnexploredApproach(
        iteration: Int,
        exploredApproaches: Set<String>
    ) -> String {
        let availableApproaches = ReasoningConstants.Approaches.all

        // Filter out already explored approaches
        let unexplored = availableApproaches.filter { !exploredApproaches.contains($0) }

        // Return the next unexplored approach or cycle back if all explored
        if !unexplored.isEmpty {
            return unexplored[min(iteration - PRDGeneratorConstants.Iterations.iterationOffset, unexplored.count - PRDGeneratorConstants.ArrayOperations.incrementValue)]
        } else {
            // If all approaches explored, cycle back with variation
            let index = (iteration - PRDGeneratorConstants.Iterations.iterationOffset) % availableApproaches.count
            return availableApproaches[index] + ReasoningConstants.Approaches.refinedSuffix
        }
    }

    // Removed overly complex approach selection and constraint building
    // per 2025 research showing simpler prompts work better

    private func calculateEnhancedConfidence(
        chain: ThoughtChain,
        iteration: Int
    ) -> Float {
        // 2025 approach: Trust the model's self-assessed confidence more
        // Research shows models are better at self-evaluation now
        var baseConfidence = chain.confidence

        // Small adjustments based on quality indicators
        if chain.thoughts.count >= ReasoningConstants.Confidence.minThoughtCount {
            baseConfidence += ReasoningConstants.Confidence.thoughtCountBonus
        }

        if chain.assumptions.count > PRDGeneratorConstants.Assumptions.noAssumptionsPresent && chain.assumptions.count <= ReasoningConstants.Confidence.maxAssumptionCount {
            // Having some but not too many assumptions is good
            baseConfidence += ReasoningConstants.Confidence.assumptionBonus
        }

        // Iteration learning bonus (smaller per 2025 findings)
        baseConfidence += Float(iteration) * ReasoningConstants.Confidence.iterationBonus

        // Evidence bonus
        let hasConcreteEvidence = chain.conclusion.contains(where: { char in
            PRDGeneratorConstants.Parsing.confidenceCharacters.contains(char)
        })
        if hasConcreteEvidence {
            baseConfidence += ReasoningConstants.Confidence.alternativePathBonus
        }

        return min(ReasoningConstants.Confidence.maxConfidence, baseConfidence)
    }

    /// Generate risk assessment based on reasoning
    public func assessRisks(from thoughtChain: ThoughtChain) -> String {
        var risks = PRDConstants.YAMLFormatting.identifiedRisksHeader

        // Analyze warnings from thought chain
        let warnings = thoughtChain.thoughts.filter { $0.type == .warning }
        for (index, warning) in warnings.enumerated() {
            risks += String(format: PRDConstants.YAMLFormatting.riskItemFormat, index + PRDGeneratorConstants.ArrayOperations.incrementValue, warning.content)
        }

        // Add assumption-based risks
        let criticalAssumptions = thoughtChain.assumptions.filter { $0.impact == .critical }
        if !criticalAssumptions.isEmpty {
            risks += PRDConstants.YAMLFormatting.criticalAssumptionsHeader
            for assumption in criticalAssumptions {
                risks += String(format: PRDConstants.YAMLFormatting.assumptionRiskFormat, assumption.statement)
            }
        }

        return risks
    }

    /// Generate alternative approaches section
    public func formatAlternatives(_ thoughtChain: ThoughtChain) -> String {
        guard !thoughtChain.alternatives.isEmpty else {
            return ""
        }

        var section = PRDConstants.YAMLFormatting.alternativesHeader

        for (index, alternative) in thoughtChain.alternatives.enumerated() {
            section += String(format: PRDConstants.YAMLFormatting.alternativeItemFormat, index + PRDGeneratorConstants.ArrayOperations.incrementValue, alternative.description)
            section += String(format: PRDConstants.YAMLFormatting.probabilityFormat, alternative.probability)
            section += String(format: PRDConstants.YAMLFormatting.prosFormat, alternative.pros.joined(separator: ", "))
            section += String(format: PRDConstants.YAMLFormatting.consFormat, alternative.cons.joined(separator: ", "))
        }

        return section
    }
}