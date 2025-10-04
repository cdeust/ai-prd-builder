import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Main orchestrator that coordinates all PRD generation components
public final class PRDOrchestrator {
    private let provider: AIProvider
    private let configuration: Configuration
    private let interactionHandler: UserInteractionHandler

    // Components
    private let inputProcessor: InputProcessor
    private let requirementsAnalyzer: RequirementsAnalyzer
    private let stackDiscovery: StackDiscovery
    private let phaseGenerator: PhaseGenerator
    private let documentAssembler: DocumentAssembler
    private let assumptionTracker: AssumptionTracker
    private let reportFormatter: ReportFormatter
    private let sectionGenerator: SectionGenerator
    private let taskContextDetector: TaskContextDetector

    // State
    private var stackContext: StackContext?
    private var enrichedRequirements: EnrichedRequirements?
    private var codebaseContext: String? // Optional codebase context for generation

    public init(
        provider: AIProvider,
        configuration: Configuration,
        interactionHandler: UserInteractionHandler? = nil,
        codebaseContext: String? = nil,
        contextRequestPort: ContextRequestPort? = nil
    ) {
        self.codebaseContext = codebaseContext
        self.provider = provider
        self.configuration = configuration
        self.interactionHandler = interactionHandler ?? ConsoleInteractionHandler()
        self.assumptionTracker = AssumptionTracker(provider: provider)
        self.reportFormatter = ReportFormatter()

        // Initialize components
        self.inputProcessor = InputProcessor(provider: provider, configuration: configuration)
        self.requirementsAnalyzer = RequirementsAnalyzer(
            provider: provider,
            interactionHandler: self.interactionHandler,
            configuration: configuration,
            contextRequestPort: contextRequestPort
        )
        self.stackDiscovery = StackDiscovery(provider: provider, interactionHandler: self.interactionHandler)
        self.documentAssembler = DocumentAssembler(interactionHandler: self.interactionHandler)
        self.sectionGenerator = SectionGenerator(provider: provider, configuration: configuration)
        self.taskContextDetector = TaskContextDetector()

        // Extract provider name for context management
        let providerName = provider.name

        self.phaseGenerator = PhaseGenerator(
            provider: provider,
            configuration: configuration,
            assumptionTracker: assumptionTracker,
            interactionHandler: self.interactionHandler,
            sectionGenerator: sectionGenerator,
            providerName: providerName
        )
    }

    /// Set request context for context queries
    public func setRequestContext(requestId: UUID?, projectId: UUID?) {
        requirementsAnalyzer.setRequestContext(requestId: requestId, projectId: projectId)
    }

    /// Orchestrate PRD generation from processed input
    public func orchestrateGeneration(
        from processedInput: ProcessedInput,
        originalInput: String
    ) async throws -> PRDocument {
        var sections: [CommonModels.PRDSection] = []

        // Detect task type
        let taskType = taskContextDetector.detectTaskType(from: originalInput)
        let contextAssumptions = taskContextDetector.getContextAssumptions(for: taskType)

        interactionHandler.showProgress("Generating Interactive PRD...")
        interactionHandler.showInfo("Task Type: \(taskType)")

        // Display input processing feedback
        displayInputFeedback(processedInput: processedInput)

        // Phase 0: Analyze requirements AND stack, collect all clarifications upfront
        var analysisInput = processedInput.combinedContent

        // If codebase context was passed during initialization, include it
        if let codebaseCtx = self.codebaseContext {
            analysisInput += "\n\n## Existing Codebase Context\n\n" + codebaseCtx
        }

        // Detect if codebase context is present in the input (from enriched description or initialization)
        let hasCodebaseContext = analysisInput.contains("## Codebase Context") ||
                                 self.codebaseContext != nil

        let enrichedReqs = try await requirementsAnalyzer.analyzeAndClarify(input: analysisInput, hasCodebaseContext: hasCodebaseContext)
        self.enrichedRequirements = enrichedReqs

        // Use enriched input for all subsequent phases
        let workingInput = enrichedReqs.inputForGeneration

        // Phase 1: Stack Discovery (with codebase context interception if available)
        let discoveredStack: StackContext

        // Extract structured codebase context for auto-answering questions
        let structuredCodebase = extractCodebaseContext(from: analysisInput)
        if let codebase = structuredCodebase {
            stackDiscovery.setCodebaseContext(codebase)
        }

        if hasCodebaseContext {
            // Tech stack info is in the codebase context, use it to auto-answer questions
            interactionHandler.showInfo("✅ Tech stack detected from codebase context - will auto-answer technical questions")
            discoveredStack = try await stackDiscovery.discoverTechnicalStack(input: workingInput, skipQuestions: false)
        } else {
            discoveredStack = try await stackDiscovery.discoverTechnicalStack(input: workingInput)
        }
        self.stackContext = discoveredStack

        // Set generation context for PhaseGenerator
        // This enables context-aware section generation that respects token limits
        phaseGenerator.setGenerationContext(
            fullInput: workingInput,
            enrichedRequirements: enrichedReqs,
            stackContext: discoveredStack
        )

        // Add requirements analysis summary if clarifications were provided
        if enrichedReqs.wasClarified {
            sections.append(PRDSection(
                title: "Requirements Analysis & Clarifications",
                content: reportFormatter.formatRequirementsAnalysis(enrichedReqs)
            ))
        }

        // Add context section
        sections.append(PRDSection(
            title: "Task Context",
            content: contextAssumptions
        ))

        // Add stack context section (only if greenfield or explicitly needed)
        if taskType == .greenfield {
            sections.append(PRDSection(
                title: PRDDisplayConstants.SectionNames.technicalStackContext,
                content: reportFormatter.formatStackContext(discoveredStack)
            ))
        }

        // Generate phases based on task type
        sections.append(try await phaseGenerator.generateProductOverview(input: workingInput))

        // Only include detailed sections for greenfield or when needed
        if taskType == .greenfield {
            sections.append(try await phaseGenerator.generateUserStories(input: workingInput))
            sections.append(try await phaseGenerator.generateFeatures(input: workingInput))
            sections.append(try await phaseGenerator.generateDataModel(input: workingInput))
            sections.append(try await phaseGenerator.generateAPIOperations(input: workingInput, stack: discoveredStack))
            sections.append(try await phaseGenerator.generateTestSpecifications(input: workingInput, stack: discoveredStack))
            sections.append(try await phaseGenerator.generateConstraints(input: workingInput, stack: discoveredStack))
        } else {
            // For incremental tasks, only include what's changing
            if taskType != .configuration {
                sections.append(try await phaseGenerator.generateFeatures(input: workingInput))
            }

            if taskType == .incremental {
                // Check if data model changes are needed
                let dataModelSection = try await phaseGenerator.generateDataModel(input: workingInput)
                if !dataModelSection.content.contains("No data model changes") {
                    sections.append(dataModelSection)
                }

                // Check if API changes are needed
                let apiSection = try await phaseGenerator.generateAPIOperations(input: workingInput, stack: discoveredStack)
                if !apiSection.content.contains("Uses existing API") {
                    sections.append(apiSection)
                }
            }

            if taskType != .configuration {
                sections.append(try await phaseGenerator.generateTestSpecifications(input: workingInput, stack: discoveredStack))
            }
        }

        sections.append(try await phaseGenerator.generateValidationCriteria(input: workingInput))
        sections.append(try await phaseGenerator.generateRoadmap(input: workingInput, stack: discoveredStack))

        // Only include assumptions for complex tasks
        if taskType == .greenfield || taskType == .incremental {
            sections.append(try await phaseGenerator.generateAssumptionReport(assumptionTracker: assumptionTracker))
        }

        // Display completion summary
        documentAssembler.displayCompletionSummary(sections: sections)

        // Assemble final document with professional analysis
        let title = reportFormatter.formatTitle(originalInput)
        return documentAssembler.assembleDocument(
            title: title,
            sections: sections,
            professionalAnalysis: enrichedReqs.professionalAnalysis
        )
    }

    private func displayInputFeedback(processedInput: ProcessedInput) {
        if processedInput.hasMockups {
            interactionHandler.showProgress(String(format: PRDDisplayConstants.ProgressMessages.analyzingMockupsFormat, processedInput.mockupCount))
        } else {
            interactionHandler.showProgress(PRDDisplayConstants.ProgressMessages.analyzingTextOnly)
        }
    }

    /// Extract structured codebase context from analysis input
    /// Parses the codebase context section to extract languages, frameworks, etc.
    private func extractCodebaseContext(from input: String) -> CodebaseContextInterceptor.CodebaseContext? {
        // Look for codebase context markers
        guard input.contains("## Existing Codebase Context") || input.contains("## Codebase Context") else {
            return nil
        }

        var languages: [String: Int] = [:]
        var frameworks: [String] = []
        var architecturePatterns: [String] = []
        var repositoryUrl = ""
        var repositoryBranch = "main"

        // Split input into lines for parsing
        let lines = input.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Extract repository URL
            if trimmed.hasPrefix("**Repository:**") || trimmed.contains("Repository:") {
                let parts = trimmed.components(separatedBy: " ")
                if parts.count >= 2 {
                    repositoryUrl = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "*()"))
                }
                // Extract branch if present
                if trimmed.contains("branch:") {
                    let branchParts = trimmed.components(separatedBy: "branch:")
                    if branchParts.count > 1 {
                        repositoryBranch = branchParts[1].trimmingCharacters(in: CharacterSet(charactersIn: " *()"))
                    }
                }
            }

            // Extract languages
            if trimmed.hasPrefix("**Languages:**") || trimmed.contains("Languages:") {
                let languagesPart = trimmed.replacingOccurrences(of: "**Languages:**", with: "")
                    .replacingOccurrences(of: "Languages:", with: "")
                    .trimmingCharacters(in: .whitespaces)

                let languageList = languagesPart.components(separatedBy: ",")
                for (idx, lang) in languageList.enumerated() {
                    let langName = lang.trimmingCharacters(in: .whitespaces)
                    // Assign decreasing weights based on order (primary language gets highest weight)
                    languages[langName] = 1000 - (idx * 100)
                }
            }

            // Extract frameworks
            if trimmed.hasPrefix("**Frameworks:**") || trimmed.contains("Frameworks:") {
                let frameworksPart = trimmed.replacingOccurrences(of: "**Frameworks:**", with: "")
                    .replacingOccurrences(of: "Frameworks:", with: "")
                    .trimmingCharacters(in: .whitespaces)

                frameworks = frameworksPart.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }

            // Extract architecture patterns
            if trimmed.hasPrefix("**Architecture:**") || trimmed.contains("Architecture:") {
                let archPart = trimmed.replacingOccurrences(of: "**Architecture:**", with: "")
                    .replacingOccurrences(of: "Architecture:", with: "")
                    .trimmingCharacters(in: .whitespaces)

                architecturePatterns = archPart.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        }

        // Only return if we found meaningful data
        guard !languages.isEmpty || !frameworks.isEmpty else {
            return nil
        }

        return CodebaseContextInterceptor.CodebaseContext(
            languages: languages,
            frameworks: frameworks,
            architecturePatterns: architecturePatterns,
            repositoryUrl: repositoryUrl,
            repositoryBranch: repositoryBranch
        )
    }
}
