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

    public init(
        provider: AIProvider,
        configuration: Configuration,
        interactionHandler: UserInteractionHandler? = nil
    ) {
        self.provider = provider
        self.configuration = configuration
        self.interactionHandler = interactionHandler ?? ConsoleInteractionHandler()
        self.assumptionTracker = AssumptionTracker(provider: provider)
        self.reportFormatter = ReportFormatter()

        // Initialize components
        self.inputProcessor = InputProcessor(provider: provider, configuration: configuration)
        self.requirementsAnalyzer = RequirementsAnalyzer(provider: provider, interactionHandler: self.interactionHandler)
        self.stackDiscovery = StackDiscovery(provider: provider, interactionHandler: self.interactionHandler)
        self.documentAssembler = DocumentAssembler()
        self.sectionGenerator = SectionGenerator(provider: provider)
        self.taskContextDetector = TaskContextDetector()
        self.phaseGenerator = PhaseGenerator(
            provider: provider,
            configuration: configuration,
            assumptionTracker: assumptionTracker,
            interactionHandler: self.interactionHandler,
            sectionGenerator: sectionGenerator
        )
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

        print("\n🚀 Generating Interactive PRD...")
        print("📋 Task Type: \(taskType)")

        // Display input processing feedback
        displayInputFeedback(processedInput: processedInput)

        // Phase 0: Analyze requirements AND stack, collect all clarifications upfront
        let enrichedReqs = try await requirementsAnalyzer.analyzeAndClarify(input: processedInput.combinedContent)
        self.enrichedRequirements = enrichedReqs

        // Use enriched input for all subsequent phases
        let workingInput = enrichedReqs.inputForGeneration

        // Phase 1: Stack Discovery
        let discoveredStack = try await stackDiscovery.discoverTechnicalStack(input: workingInput)
        self.stackContext = discoveredStack

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

        // Assemble final document
        let title = reportFormatter.formatTitle(originalInput)
        return documentAssembler.assembleDocument(title: title, sections: sections)
    }

    private func displayInputFeedback(processedInput: ProcessedInput) {
        if processedInput.hasMockups {
            print(String(format: PRDDisplayConstants.ProgressMessages.analyzingMockupsFormat, processedInput.mockupCount))
        } else {
            print(PRDDisplayConstants.ProgressMessages.analyzingTextOnly)
        }
    }
}