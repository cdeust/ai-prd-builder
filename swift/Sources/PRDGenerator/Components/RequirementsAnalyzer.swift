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

    // Professional analyzers
    private let conflictAnalyzer: ConflictAnalyzer
    private let challengePredictor: ChallengePredictor
    private let conflictChallengeValidator: ConflictChallengeValidator
    private let configuration: Configuration

    // Store request context for context queries
    private var currentRequestId: UUID?
    private var currentProjectId: UUID?

    public init(
        provider: AIProvider,
        interactionHandler: UserInteractionHandler,
        configuration: Configuration = Configuration(),
        contextRequestPort: ContextRequestPort? = nil
    ) {
        self.analysisOrchestrator = AnalysisOrchestrator(provider: provider)
        self.confidenceEvaluator = ConfidenceEvaluator()
        self.clarificationCollector = ClarificationCollector(
            interactionHandler: interactionHandler,
            contextRequestPort: contextRequestPort
        )
        self.requirementsEnricher = RequirementsEnricher()
        self.interactionHandler = interactionHandler

        // Initialize professional analyzers
        self.conflictAnalyzer = ConflictAnalyzer(provider: provider)
        self.challengePredictor = ChallengePredictor(provider: provider)
        self.conflictChallengeValidator = ConflictChallengeValidator()
        self.configuration = configuration
    }

    /// Set request context for context queries
    public func setRequestContext(requestId: UUID?, projectId: UUID?) {
        self.currentRequestId = requestId
        self.currentProjectId = projectId
    }

    /// Analyzes the input, technical stack, and collects all clarifications before generation starts
    public func analyzeAndClarify(input: String, hasCodebaseContext: Bool = false) async throws -> EnrichedRequirements {
        interactionHandler.showProgress(PRDAnalysisConstants.AnalysisMessages.analyzingCompleteness)

        // Step 2: Perform parallel analysis of requirements and stack (skip stack if codebase provided)
        async let requirementsTask = analysisOrchestrator.analyzeRequirements(input: input)

        let analysis = try await requirementsTask
        let stackAnalysis: RequirementsAnalysis

        if hasCodebaseContext {
            // Codebase context provided - skip tech stack analysis and use high confidence
            interactionHandler.showInfo("✅ Tech stack detected from codebase context - skipping tech stack questions")
            stackAnalysis = RequirementsAnalysis(
                confidence: 95,
                clarificationsNeeded: [],
                assumptions: ["Using tech stack from linked codebase"],
                gaps: []
            )
        } else {
            // No codebase context - perform tech stack analysis
            stackAnalysis = try await analysisOrchestrator.analyzeTechnicalStack(input: input)
        }

        // Step 1.5: Early professional analysis to detect architectural issues
        let coreRequirements = extractCoreRequirements(from: input)
        async let earlyConflictsTask = conflictAnalyzer.analyze(coreRequirements)
        async let earlyChallengesTask = challengePredictor.predictChallenges(from: coreRequirements)

        var earlyConflicts = try await earlyConflictsTask
        var earlyChallenges = try await earlyChallengesTask

        // Validate that detected issues are actually relevant to the requirements
        earlyConflicts = conflictChallengeValidator.validateConflicts(earlyConflicts, against: input)
        earlyChallenges = conflictChallengeValidator.validateChallenges(earlyChallenges, against: input)

        // Check for generic/template issues
        let (genericConflicts, genericChallenges) = conflictChallengeValidator.detectGenericIssues(
            conflicts: earlyConflicts,
            challenges: earlyChallenges,
            requirements: input
        )

        if !genericConflicts.isEmpty || !genericChallenges.isEmpty {
            interactionHandler.showWarning("⚠️ Detected potentially irrelevant analysis:")
            genericConflicts.forEach { interactionHandler.showWarning("  - Conflict: \($0)") }
            genericChallenges.forEach { interactionHandler.showWarning("  - Challenge: \($0)") }
            interactionHandler.showInfo("Filtering to relevant issues only...")
        }

        // Calculate relevance score
        let relevanceScore = conflictChallengeValidator.calculateRelevanceScore(
            conflicts: earlyConflicts,
            challenges: earlyChallenges,
            requirements: input
        )

        if relevanceScore < 0.5 {
            interactionHandler.showWarning("⚠️ Low relevance score (\(Int(relevanceScore * 100))%) - Re-analyzing with better focus...")
            // Re-analyze with more specific prompting
            earlyConflicts = try await reanalyzeConflicts(for: input)
            earlyChallenges = try await reanalyzeChallenges(for: input)
        }

        // Step 2: Check if confidence is too low to proceed
        if confidenceEvaluator.isBelowMinimumViability(analysis.confidence) {
            return try await handleVeryLowConfidence(input: input, analysis: analysis, stackAnalysis: stackAnalysis)
        }

        // Step 3: Filter based on confidence levels
        let filteredAnalysis = confidenceEvaluator.filterByConfidence(analysis)
        let filteredStackAnalysis = confidenceEvaluator.filterByConfidence(stackAnalysis)

        // Step 3.5: Generate contextual clarifications from architectural issues
        var architecturalClarifications: [String] = []
        if !earlyConflicts.isEmpty || !earlyChallenges.isEmpty {
            architecturalClarifications = try await generateArchitecturalClarifications(
                conflicts: earlyConflicts,
                challenges: earlyChallenges
            )

            // Log what clarifications we're generating
            if !architecturalClarifications.isEmpty {
                interactionHandler.showInfo("Generated \(architecturalClarifications.count) clarification questions from architectural analysis")
            }
        }

        // Step 4: Determine if clarifications should be collected
        var enrichedInput = input
        var allClarifications: [String: String] = [:]

        let shouldAskClarifications = shouldCollectClarifications(
            filteredAnalysis: filteredAnalysis,
            filteredStackAnalysis: filteredStackAnalysis
        )

        // Always ask if we have architectural clarifications OR low confidence
        let hasArchitecturalIssues = !architecturalClarifications.isEmpty
        let needsClarification = shouldAskClarifications || hasArchitecturalIssues

        if needsClarification {
            // Combine all clarifications (architectural issues take priority)
            let combinedRequirementsClarifications = architecturalClarifications + filteredAnalysis.clarificationsNeeded

            if hasArchitecturalIssues {
                interactionHandler.showWarning("🔍 Critical architectural decisions require clarification")
            }

            // Present clarifications and get approval
            let shouldClarify = await clarificationCollector.presentClarificationsForApproval(
                requirementsClarifications: combinedRequirementsClarifications,
                stackClarifications: filteredStackAnalysis.clarificationsNeeded,
                requirementsConfidence: analysis.confidence,
                stackConfidence: stackAnalysis.confidence,
                architecturalIssues: (conflicts: earlyConflicts.count, challenges: earlyChallenges.count)
            )

            if shouldClarify {
                let (requirementsClarifications, stackClarifications) =
                    await clarificationCollector.collectBatchedClarifications(
                        requirementsClarifications: combinedRequirementsClarifications,
                        stackClarifications: filteredStackAnalysis.clarificationsNeeded,
                        requestId: currentRequestId
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

        // Professional analysis - Re-run with enriched input if clarifications were provided
        var finalConflicts: [ArchitecturalConflict]
        var finalChallenges: [TechnicalChallenge]

        if !allClarifications.isEmpty {
            // Re-analyze with enriched input
            let refinedRequirements = extractCoreRequirements(from: enrichedInput)
            async let conflictsTask = conflictAnalyzer.analyze(refinedRequirements)
            async let challengesTask = challengePredictor.predictChallenges(from: refinedRequirements)

            finalConflicts = try await conflictsTask
            finalChallenges = try await challengesTask

            // Validate again after re-analysis
            finalConflicts = conflictChallengeValidator.validateConflicts(finalConflicts, against: enrichedInput)
            finalChallenges = conflictChallengeValidator.validateChallenges(finalChallenges, against: enrichedInput)
        } else {
            // Use early analysis results
            finalConflicts = earlyConflicts
            finalChallenges = earlyChallenges
        }

        let professionalAnalysis = buildProfessionalAnalysisResult(
            conflicts: finalConflicts,
            challenges: finalChallenges,
            confidence: overallConfidence
        )

        return EnrichedRequirements(
            originalInput: input,
            enrichedInput: enrichedInput,
            clarifications: allClarifications,
            assumptions: filteredAnalysis.assumptions + filteredStackAnalysis.assumptions,
            gaps: filteredAnalysis.gaps + filteredStackAnalysis.gaps,
            initialConfidence: overallConfidence,
            stackClarifications: [:], // Merged into main clarifications
            professionalAnalysis: professionalAnalysis // Always included for professional PRD
        )
    }

    // MARK: - Private Methods

    /// Detects if tech stack information is already present in the input
    private func detectExistingTechStack(in input: String) -> Bool {
        // Check for codebase context markers
        let hasCodebaseContext = input.contains("## Codebase Context")
        let hasTechStackSection = input.contains("**Tech Stack:**") || input.contains("Tech Stack:")
        let hasLanguages = input.contains("- Languages:") || input.contains("Languages:")

        // Also check for inline tech stack mentions
        let hasFrameworkMention = input.range(of: "\\b(Frameworks?|Framework):\\s*\\w+", options: .regularExpression) != nil
        let hasArchitectureMention = input.range(of: "\\b(Architecture|Patterns?):\\s*\\w+", options: .regularExpression) != nil

        // Consider tech stack present if we have codebase context with languages
        // OR if frameworks/architecture are explicitly mentioned
        return (hasCodebaseContext && hasTechStackSection && hasLanguages) ||
               (hasFrameworkMention && hasLanguages) ||
               (hasArchitectureMention && hasLanguages)
    }

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
        interactionHandler.showProgress(PRDAnalysisConstants.AnalysisMessages.reanalyzing)

        let refinedAnalysis = try await analysisOrchestrator.reanalyzeWithContext(
            enrichedInput: enrichedInput
        )

        if refinedAnalysis.confidence > originalAnalysis.confidence {
            interactionHandler.showInfo(String(format: PRDAnalysisConstants.AnalysisMessages.confidenceImproved,
                        originalAnalysis.confidence, refinedAnalysis.confidence))
        }
    }

    /// Generate clarification questions based on detected architectural issues
    private func generateArchitecturalClarifications(
        conflicts: [ArchitecturalConflict],
        challenges: [TechnicalChallenge]
    ) async throws -> [String] {
        var questions: [String] = []

        // Only generate questions if we have real, relevant issues
        let criticalConflicts = conflicts.filter { $0.severity == .critical || $0.severity == .high }
        let criticalChallenges = challenges.filter { $0.priority == .critical || $0.priority == .high }

        // Generate questions from conflicts
        for conflict in criticalConflicts.prefix(2) {
            let question = await generateConflictQuestion(conflict)
            if !question.isEmpty && !question.contains("How would you like to resolve") {
                questions.append(question)
            }
        }

        // Generate questions from challenges
        for challenge in criticalChallenges.prefix(2) {
            let question = await generateChallengeQuestion(challenge)
            if !question.isEmpty && !question.contains("What are your requirements regarding") {
                questions.append(question)
            }
        }

        // Filter out generic questions
        questions = questions.filter { question in
            // Remove questions that are too generic
            !question.lowercased().contains("oauth") &&
            !question.lowercased().contains("microservice") &&
            !question.lowercased().contains("real-time") &&
            !question.lowercased().contains("offline") &&
            !question.lowercased().contains("encryption") &&
            !question.lowercased().contains("csv export")
        }

        return questions
    }

    private func generateConflictQuestion(_ conflict: ArchitecturalConflict) async -> String {
        // First check if this is a real conflict from the requirements
        let conflictTerms = "\(conflict.requirement1) \(conflict.requirement2)".lowercased()

        // Skip generic conflicts
        let genericPatterns = ["real-time", "offline", "encryption", "microservice", "acid", "oauth"]
        for pattern in genericPatterns {
            if conflictTerms.contains(pattern) {
                return "" // Skip generating question for generic conflict
            }
        }

        let prompt = """
        <task>Generate clarification question</task>

        <conflict>
        Requirement 1: \(conflict.requirement1)
        Requirement 2: \(conflict.requirement2)
        Tradeoff: \(conflict.resolution.approach)
        </conflict>

        <instruction>
        Generate ONE specific question to understand which approach the user prefers.
        The question must directly address this conflict.
        Return ONLY the question, no explanation.
        </instruction>
        """

        let messages = [
            ChatMessage(role: .system, content: "You are helping resolve architectural conflicts by asking targeted questions."),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await analysisOrchestrator.aiProvider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        case .failure:
            // Fallback to generic conflict question
            return "How would you like to resolve the conflict between '\(String(conflict.requirement1.prefix(50)))' and '\(String(conflict.requirement2.prefix(50)))'?"
        }
    }

    private func generateChallengeQuestion(_ challenge: TechnicalChallenge) async -> String {
        // Skip generic challenges
        let challengeText = challenge.description.lowercased()
        let genericPatterns = ["oauth", "csv export", "1m rows", "n+1", "ios background", "payment processor"]
        for pattern in genericPatterns {
            if challengeText.contains(pattern) {
                return "" // Skip generic challenge
            }
        }

        let prompt = """
        <task>Generate clarification question</task>

        <challenge>
        Issue: \(challenge.description)
        Impact: \(challenge.impact.severity)
        Category: \(challenge.category)
        </challenge>

        <instruction>
        Generate ONE specific question to understand the user's requirements or constraints.
        The question must directly address this technical challenge.
        Focus on gathering information that would affect the implementation approach.
        Return ONLY the question, no explanation.
        </instruction>
        """

        let messages = [
            ChatMessage(role: .system, content: "You are helping prevent technical challenges by asking targeted questions."),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await analysisOrchestrator.aiProvider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        case .failure:
            return "What are your requirements regarding \(challenge.category)?"
        }
    }

    /// Build professional analysis result with detailed conflict and challenge information
    private func buildProfessionalAnalysisResult(
        conflicts: [ArchitecturalConflict],
        challenges: [TechnicalChallenge],
        confidence: Int
    ) -> CommonModels.ProfessionalAnalysisResult {
        interactionHandler.showProgress("🔍 Building professional analysis report...")

        // Build detailed executive summary
        var executiveSummary = "## 🔍 Professional Architecture Analysis\n\n"

        if !conflicts.isEmpty {
            executiveSummary += "### ⚠️ Architectural Conflicts (\(conflicts.count) detected)\n\n"
            interactionHandler.showWarning("⚠️ Found \(conflicts.count) architectural conflicts")

            for conflict in conflicts {
                let icon = conflict.severity == .critical ? "🔴" :
                          conflict.severity == .high ? "🟠" : "🟡"
                executiveSummary += "\(icon) **Conflict**: \(conflict.requirement1) ↔ \(conflict.requirement2)\n"
                executiveSummary += "   - Type: \(conflict.conflictType)\n"
                executiveSummary += "   - Resolution: \(conflict.resolution.approach)\n\n"

                // Stream via WebSocket if available
                if let wsHandler = interactionHandler as? WebSocketInteractionHandler {
                    let severityStr = conflict.severity == .critical ? "critical" :
                                    conflict.severity == .high ? "high" : "medium"
                    wsHandler.showArchitecturalConflict(
                        "\(conflict.requirement1) vs \(conflict.requirement2): \(conflict.conflictType)",
                        severity: severityStr
                    )
                } else if conflict.severity == .critical {
                    interactionHandler.showWarning("  🔴 \(conflict.requirement1) vs \(conflict.requirement2)")
                }
            }
        }

        if !challenges.isEmpty {
            executiveSummary += "### 🚨 Technical Challenges (\(challenges.count) predicted)\n\n"
            let criticalCount = challenges.filter { $0.priority == .critical }.count
            if criticalCount > 0 {
                interactionHandler.showWarning("🚨 \(criticalCount) critical challenges detected")
            }

            for challenge in challenges {
                let icon = challenge.priority == .critical ? "🚨" :
                          challenge.priority == .high ? "⚠️" : "ℹ️"
                executiveSummary += "\(icon) **\(challenge.category)**: \(challenge.title)\n"
                executiveSummary += "   - Impact: \(challenge.impact.severity)\n"
                executiveSummary += "   - Detection: \(challenge.detectionPoint)\n"
                if !challenge.preventiveMeasures.isEmpty {
                    executiveSummary += "   - Prevention: \(challenge.preventiveMeasures.first?.action ?? "N/A")\n"
                }
                executiveSummary += "\n"

                // Stream via WebSocket if available
                if let wsHandler = interactionHandler as? WebSocketInteractionHandler {
                    let priorityStr = challenge.priority == .critical ? "critical" :
                                    challenge.priority == .high ? "high" : "medium"
                    wsHandler.showTechnicalChallenge(
                        "\(challenge.title): \(challenge.description)",
                        priority: priorityStr
                    )
                }
            }
        }

        // Add confidence analysis
        executiveSummary += "### 📊 Confidence Analysis\n\n"
        executiveSummary += "- Overall Confidence: \(confidence)%\n"
        if confidence < 70 {
            executiveSummary += "- ⚠️ Low confidence - additional clarifications recommended\n"
        }

        // Build critical issues list
        let criticalIssues = conflicts.filter { $0.severity == .critical }.map {
            "Conflict: \($0.requirement1) vs \($0.requirement2)"
        } + challenges.filter { $0.priority == .critical }.map {
            "Challenge: \($0.title)"
        }

        return CommonModels.ProfessionalAnalysisResult(
            hasCriticalIssues: !criticalIssues.isEmpty,
            executiveSummary: executiveSummary,
            conflictCount: conflicts.count,
            challengeCount: challenges.count,
            complexityScore: nil,
            blockingIssues: criticalIssues
        )
    }

    private func extractCoreRequirements(from enrichedInput: String) -> String {
        // Extract just the essential requirements without clarifications, assumptions, etc.
        let lines = enrichedInput.components(separatedBy: "\n")
        var requirements: [String] = []
        var currentRequirement = ""
        var skipSection = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip enrichment sections
            if trimmed.hasPrefix("## Clarifications") ||
               trimmed.hasPrefix("## Assumptions") ||
               trimmed.hasPrefix("## Technical Context") ||
               trimmed.hasPrefix("## Stack Context") {
                skipSection = true
                // Save any pending requirement
                if !currentRequirement.isEmpty {
                    requirements.append(currentRequirement)
                    currentRequirement = ""
                }
                continue
            }

            // Reset skip flag on new main sections
            if trimmed.hasPrefix("##") && !trimmed.contains("Clarifications") &&
               !trimmed.contains("Assumptions") && !trimmed.contains("Context") {
                skipSection = false
                continue
            }

            if skipSection {
                continue
            }

            // Detect requirement markers
            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") ||
               (trimmed.first?.isNumber ?? false && trimmed.contains(".")) {
                // Save previous requirement
                if !currentRequirement.isEmpty {
                    requirements.append(currentRequirement)
                }
                currentRequirement = trimmed
            } else if !trimmed.isEmpty {
                // Continue current requirement or start new one
                if !currentRequirement.isEmpty {
                    currentRequirement += " " + trimmed
                } else if !trimmed.hasPrefix("#") { // Not a header
                    currentRequirement = trimmed
                }
            }
        }

        // Add last requirement
        if !currentRequirement.isEmpty {
            requirements.append(currentRequirement)
        }

        // If no requirements found, fall back to original text without enrichments
        if requirements.isEmpty {
            let coreLines = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty &&
                       !trimmed.contains("Clarification") &&
                       !trimmed.contains("Assumption") &&
                       !trimmed.contains("Context")
            }
            return coreLines.prefix(30).joined(separator: "\n")
        }

        // Smart prioritization: keep most important requirements
        let prioritized = prioritizeRequirements(requirements)

        // Return a reasonable subset that fits in context window
        return formatRequirementsForAnalysis(prioritized)
    }

    private func prioritizeRequirements(_ requirements: [String]) -> [String] {
        // Keywords that indicate critical requirements
        let criticalKeywords = [
            "real-time", "offline", "encryption", "security", "scale",
            "concurrent", "performance", "latency", "sync", "distributed",
            "authentication", "authorization", "privacy", "compliance"
        ]

        // Score each requirement
        let scored = requirements.map { req -> (requirement: String, score: Int) in
            let lower = req.lowercased()
            var score = 0

            // Check for critical keywords
            for keyword in criticalKeywords {
                if lower.contains(keyword) {
                    score += 10
                }
            }

            // Prefer requirements with technical details
            if lower.contains("ms") || lower.contains("users") || lower.contains("gb") {
                score += 5
            }

            // Prefer shorter, more concrete requirements
            if req.count < 200 {
                score += 3
            }

            return (requirement: req, score: score)
        }

        // Sort by score and return
        return scored
            .sorted { $0.score > $1.score }
            .map { $0.requirement }
    }

    private func formatRequirementsForAnalysis(_ requirements: [String]) -> String {
        var result = ""
        var charCount = 0
        let maxChars = 800 // Conservative limit for context window

        for req in requirements {
            // Clean up requirement
            let cleaned = req
                .replacingOccurrences(of: "^[\\-•\\*\\d\\.\\s]+", with: "",
                                    options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            // Truncate individual requirements if too long
            let truncated = cleaned.count > 150 ?
                String(cleaned.prefix(147)) + "..." : cleaned

            // Check if adding this requirement would exceed limit
            if charCount + truncated.count > maxChars {
                break
            }

            if !result.isEmpty {
                result += "\n"
            }
            result += "- " + truncated
            charCount += truncated.count + 3 // +3 for "- " and newline
        }

        return result
    }

    private func reanalyzeConflicts(for input: String) async throws -> [ArchitecturalConflict] {
        let prompt = """
        <task>Analyze for conflicts</task>

        <input>\(input)</input>

        <instruction>
        Identify ONLY conflicts that exist between requirements explicitly stated in the input above.
        DO NOT add conflicts from other systems.
        DO NOT assume features not mentioned.
        Each conflict must reference actual text from the input.
        Return empty list if no conflicts exist.
        </instruction>
        """

        // Use a more focused analysis
        return try await conflictAnalyzer.analyze(prompt)
    }

    private func reanalyzeChallenges(for input: String) async throws -> [TechnicalChallenge] {
        let prompt = """
        <task>Predict technical challenges</task>

        <input>\(input)</input>

        <instruction>
        Identify technical challenges for implementing ONLY the features described in the input.
        Each challenge must be directly related to a stated requirement.
        DO NOT add generic challenges.
        DO NOT assume scale or features not mentioned.
        Return empty list if no significant challenges exist.
        </instruction>
        """

        return try await challengePredictor.predictChallenges(from: prompt)
    }

    private func handleVeryLowConfidence(
        input: String,
        analysis: RequirementsAnalysis,
        stackAnalysis: RequirementsAnalysis
    ) async throws -> EnrichedRequirements {
        interactionHandler.showInfo(
            String(format: PRDAnalysisConstants.AnalysisMessages.confidenceTooLow, analysis.confidence)
        )

        // Collect essential clarifications
        let essentialResponses = await clarificationCollector.collectEssentialClarifications()

        // Enrich input with essentials
        let enrichedInput = requirementsEnricher.enrichWithEssentials(
            original: input,
            essentialResponses: essentialResponses
        )

        // Re-analyze with essential information
        interactionHandler.showProgress(PRDAnalysisConstants.AnalysisMessages.reanalyzing)
        let improvedAnalysis = try await analysisOrchestrator.reanalyzeWithContext(
            enrichedInput: enrichedInput
        )

        interactionHandler.showInfo(String(format: PRDAnalysisConstants.AnalysisMessages.confidenceImproved,
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