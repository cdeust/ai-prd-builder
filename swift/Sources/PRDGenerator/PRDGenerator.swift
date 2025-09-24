import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Main PRD Generator orchestrator - coordinates all components for PRD generation
public final class PRDGenerator: PRDGeneratorProtocol {
    private let provider: AIProvider
    private let configuration: Configuration
    private let assumptionTracker: AssumptionTracker
    private let interactionHandler: UserInteractionHandler

    // Components
    private let requirementsAnalyzer: RequirementsAnalyzer
    private let stackDiscovery: StackDiscovery
    private let sectionGenerator: SectionGenerator
    private let validationHandler: ValidationHandler
    private let reportFormatter: ReportFormatter

    private var stackContext: StackContext?
    private var enrichedRequirements: EnrichedRequirements?

    public init(
        provider: AIProvider,
        configuration: Configuration,
        interactionHandler: UserInteractionHandler? = nil
    ) {
        self.provider = provider
        self.configuration = configuration
        self.assumptionTracker = AssumptionTracker(provider: provider)
        self.interactionHandler = interactionHandler ?? ConsoleInteractionHandler()

        // Initialize components
        self.requirementsAnalyzer = RequirementsAnalyzer(provider: provider, interactionHandler: self.interactionHandler)
        self.stackDiscovery = StackDiscovery(provider: provider, interactionHandler: self.interactionHandler)
        self.sectionGenerator = SectionGenerator(provider: provider)
        self.validationHandler = ValidationHandler(
            provider: provider,
            assumptionTracker: assumptionTracker,
            interactionHandler: self.interactionHandler,
            sectionGenerator: sectionGenerator,
            configuration: configuration
        )
        self.reportFormatter = ReportFormatter()
    }

    /// Generate PRD (protocol conformance)
    public func generatePRD(from input: String) async throws -> PRDocument {
        return try await generatePRDDocument(from: input)
    }

    /// Generate PRD and optionally export to file
    public func generatePRDWithExport(
        from input: String,
        exportTo path: String? = nil,
        format: PRDExporter.ExportFormat = .markdown
    ) async throws -> (document: PRDocument, exportPath: String?) {
        let document = try await generatePRDDocument(from: input)

        var exportPath: String?
        if path != nil || ProcessInfo.processInfo.environment["AUTO_EXPORT"] != nil {
            let exporter = PRDExporter()
            exportPath = try exporter.export(document: document, format: format, to: path)
            DebugLogger.always("✅ PRD exported to: \(exportPath!)")
        }

        return (document, exportPath)
    }

    private func generatePRDDocument(from input: String) async throws -> PRDocument {
        var sections: [CommonModels.PRDSection] = []

        print(PRDConstants.PhaseMessages.interactivePRDGeneration)
        print(PRDConstants.Messages.analyzingRequirements)

        // Phase 0: Analyze requirements AND stack, collect all clarifications upfront
        let enrichedReqs = try await requirementsAnalyzer.analyzeAndClarify(input: input)
        self.enrichedRequirements = enrichedReqs

        // Use enriched input for all subsequent phases
        let workingInput = enrichedReqs.inputForGeneration

        // Phase 1: Stack Discovery (now uses pre-collected clarifications)
        // The stack discovery now has much better context from the clarifications
        let discoveredStack = try await stackDiscovery.discoverTechnicalStack(input: workingInput)
        self.stackContext = discoveredStack

        // Add requirements analysis summary if clarifications were provided
        if enrichedReqs.wasClarified {
            sections.append(PRDSection(
                title: "Requirements Analysis & Clarifications",
                content: reportFormatter.formatRequirementsAnalysis(enrichedReqs)
            ))
        }

        // Add stack context section
        sections.append(PRDSection(
            title: PRDConstants.ExtendedSections.technicalStackContext,
            content: reportFormatter.formatStackContext(discoveredStack)
        ))

        // Phase 2: Product Overview (using enriched input)
        sections.append(try await generatePhase1Overview(input: workingInput))

        // Phase 3: User Stories
        sections.append(try await generatePhase2UserStories(input: workingInput))

        // Phase 4: Features List
        sections.append(try await generatePhase3Features(input: workingInput))

        // Phase 5: API Endpoints (simplified - no OpenAPI spec)
        sections.append(try await generatePhase4APISpec(input: workingInput, stack: discoveredStack))

        // Phase 6: Test Specifications
        sections.append(try await generatePhase5TestSpec(input: workingInput, stack: discoveredStack))

        // Phase 7: Constraints
        sections.append(try await generatePhase6Constraints(input: workingInput, stack: discoveredStack))

        // Phase 8: Validation Criteria
        sections.append(try await generatePhase7Validation(input: workingInput))

        // Phase 9: Technical Roadmap
        sections.append(try await generatePhase8Roadmap(input: workingInput, stack: discoveredStack))

        // Final Phase: Assumption Validation Report
        sections.append(try await generateAssumptionReport())

        print(PRDConstants.Messages.prdComplete)
        print(String(format: PRDConstants.Messages.overallConfidence,
                    reportFormatter.calculateOverallConfidence(sections)))

        return PRDocument(
            title: reportFormatter.formatTitle(input),
            sections: sections,
            metadata: [
                PRDConstants.MetadataKeys.generator: PRDConstants.Defaults.prdGeneratorName,
                PRDConstants.MetadataKeys.version: PRDConstants.Defaults.prdVersion,
                PRDConstants.MetadataKeys.timestamp: Date().timeIntervalSince1970,
                PRDConstants.MetadataKeys.passes: PRDConstants.Defaults.totalPasses,
                PRDConstants.MetadataKeys.approach: PRDConstants.Defaults.generationApproach
            ]
        )
    }

    // MARK: - Phase Generation Methods

    private func generatePhase1Overview(input: String) async throws -> PRDSection {
        do {
            let overview = try await validationHandler.generateWithValidation(
                input: input,
                prompt: PRDPrompts.overviewPrompt,
                sectionName: PRDConstants.Sections.productOverview
            )
            print(String(format: PRDConstants.Messages.sectionCompleteFormat,
                        PRDConstants.Sections.productOverview))
            return PRDSection(
                title: PRDConstants.Sections.productOverview,
                content: overview.content
            )
        } catch {
            print(String(format: PRDConstants.Messages.sectionFailedFormat,
                        PRDConstants.Sections.productOverview, error.localizedDescription))
            return PRDSection(
                title: PRDConstants.Sections.productOverview,
                content: String(format: PRDConstants.Messages.errorGeneratingOverview, error.localizedDescription)
            )
        }
    }

    private func generatePhase2UserStories(input: String) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase2UserStories)
        do {
            let userStories = try await validationHandler.generateWithValidation(
                input: input,
                prompt: PRDPrompts.userStoriesPrompt,
                sectionName: PRDConstants.Sections.userStories
            )
            print(String(format: PRDConstants.PhaseMessages.userStoriesGenerated, userStories.confidence))
            return PRDSection(
                title: PRDConstants.Sections.userStories,
                content: reportFormatter.formatWithClarifications(
                    userStories.content,
                    confidence: userStories.confidence,
                    clarifications: userStories.clarificationsNeeded
                )
            )
        } catch {
            print(String(format: PRDConstants.PhaseMessages.userStoriesFailed, error.localizedDescription))
            return PRDSection(
                title: PRDConstants.Sections.userStories,
                content: String(format: PRDConstants.Messages.errorGeneratingUserStories, error.localizedDescription)
            )
        }
    }

    private func generatePhase3Features(input: String) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase3Features)
        let features = try await validationHandler.generateWithValidation(
            input: input,
            prompt: PRDPrompts.featuresPrompt,
            sectionName: PRDConstants.Sections.features
        )
        print(String(format: PRDConstants.PhaseMessages.featuresGenerated, features.confidence))
        return PRDSection(
            title: PRDConstants.Sections.features,
            content: reportFormatter.formatWithClarifications(
                features.content,
                confidence: features.confidence,
                clarifications: features.clarificationsNeeded
            )
        )
    }

    private func generatePhase4APISpec(input: String, stack: StackContext) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase4ApiSpec)
        let apiPrompt = reportFormatter.enhancePromptWithStack(PRDPrompts.apiSpecPrompt, stack: stack)
        let apiSpec = try await validationHandler.generateWithValidation(
            input: input,
            prompt: apiPrompt,
            sectionName: PRDConstants.ExtendedSections.apiSpecification
        )
        print(String(format: PRDConstants.PhaseMessages.apiSpecGenerated, apiSpec.confidence))
        return PRDSection(
            title: PRDConstants.ExtendedSections.openAPISpecification,
            content: reportFormatter.formatWithStackAwareness(apiSpec.content, confidence: apiSpec.confidence)
        )
    }

    private func generatePhase5TestSpec(input: String, stack: StackContext) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase5TestSpec)
        let testPrompt = reportFormatter.enhanceTestPromptWithStack(PRDPrompts.testSpecPrompt, stack: stack)
        let testSpec = try await validationHandler.generateWithValidation(
            input: input,
            prompt: testPrompt,
            sectionName: PRDConstants.Sections.testSpec
        )
        print(String(format: PRDConstants.PhaseMessages.testSpecGenerated, testSpec.confidence))
        return PRDSection(
            title: PRDConstants.Sections.testSpec,
            content: reportFormatter.formatWithTestFramework(
                testSpec.content,
                confidence: testSpec.confidence,
                testFramework: stack.testFramework
            )
        )
    }

    private func generatePhase6Constraints(input: String, stack: StackContext) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase6Constraints)
        let constraintsPrompt = reportFormatter.enhancePromptWithStack(PRDPrompts.constraintsPrompt, stack: stack)
        let constraints = try await validationHandler.generateWithValidation(
            input: input,
            prompt: constraintsPrompt,
            sectionName: PRDConstants.Sections.constraints
        )
        print(String(format: PRDConstants.PhaseMessages.constraintsGenerated, constraints.confidence))
        return PRDSection(
            title: PRDConstants.ExtendedSections.performanceSecurityConstraints,
            content: reportFormatter.formatWithConfidence(constraints.content, confidence: constraints.confidence)
        )
    }

    private func generatePhase7Validation(input: String) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase7Validation)
        let validation = try await validationHandler.generateWithValidation(
            input: input,
            prompt: PRDPrompts.validationPrompt,
            sectionName: PRDConstants.Sections.validationCriteria
        )
        print(String(format: PRDConstants.PhaseMessages.validationGenerated, validation.confidence))
        return PRDSection(
            title: PRDConstants.Sections.validationCriteria,
            content: reportFormatter.formatWithClarifications(
                validation.content,
                confidence: validation.confidence,
                clarifications: validation.clarificationsNeeded
            )
        )
    }

    private func generatePhase8Roadmap(input: String, stack: StackContext) async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.phase8Roadmap)
        let roadmapPrompt = reportFormatter.enhanceRoadmapPromptWithStack(PRDPrompts.roadmapPrompt, stack: stack)
        let roadmap = try await validationHandler.generateWithValidation(
            input: input,
            prompt: roadmapPrompt,
            sectionName: PRDConstants.Sections.technicalRoadmap
        )
        print(String(format: PRDConstants.PhaseMessages.roadmapGenerated, roadmap.confidence))
        return PRDSection(
            title: PRDConstants.ExtendedSections.technicalRoadmapCICD,
            content: reportFormatter.formatWithPipeline(
                roadmap.content,
                confidence: roadmap.confidence,
                pipeline: stack.cicdPipeline
            )
        )
    }

    private func generateAssumptionReport() async throws -> PRDSection {
        print(PRDConstants.PhaseMessages.assumptionValidation)
        let validationReport = try await assumptionTracker.validateAll()
        return PRDSection(
            title: PRDConstants.ExtendedSections.assumptionValidationReport,
            content: reportFormatter.formatValidationReport(validationReport)
        )
    }
}