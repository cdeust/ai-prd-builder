import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles generation of individual PRD phases
public final class PhaseGenerator {
    private let sectionGenerator: SectionGenerator
    private let validationHandler: ValidationHandler
    private let reportFormatter: ReportFormatter
    private let interactionHandler: UserInteractionHandler
    private let contextManager: ContextManager
    private let providerName: String

    // Context state for section generation
    private var fullInput: String = ""
    private var enrichedRequirements: EnrichedRequirements?
    private var stackContext: StackContext?

    public init(
        provider: AIProvider,
        configuration: Configuration,
        assumptionTracker: AssumptionTracker,
        interactionHandler: UserInteractionHandler,
        sectionGenerator: SectionGenerator,
        providerName: String = "default"
    ) {
        self.sectionGenerator = sectionGenerator
        self.reportFormatter = ReportFormatter()
        self.interactionHandler = interactionHandler
        self.contextManager = ContextManager()
        self.providerName = providerName
        self.validationHandler = ValidationHandler(
            provider: provider,
            assumptionTracker: assumptionTracker,
            interactionHandler: interactionHandler,
            sectionGenerator: sectionGenerator,
            configuration: configuration
        )
    }

    /// Set generation context - called before section generation begins
    public func setGenerationContext(
        fullInput: String,
        enrichedRequirements: EnrichedRequirements?,
        stackContext: StackContext?
    ) {
        self.fullInput = fullInput
        self.enrichedRequirements = enrichedRequirements
        self.stackContext = stackContext
    }

    /// Extract section-specific context to stay within token limits
    private func getSectionContext(for sectionName: String) -> String {
        return contextManager.extractContextForSection(
            sectionName: sectionName,
            fullInput: fullInput,
            enrichedRequirements: enrichedRequirements,
            stackContext: stackContext,
            providerName: providerName
        )
    }

    // MARK: - Phase 1: Product Overview

    public func generateProductOverview(input: String) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.generatingPRD)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.taskOverview)
        let overview = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: PRDPrompts.overviewPrompt,
            sectionName: PRDDisplayConstants.SectionNames.taskOverview
        )
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.taskOverview,
            content: reportFormatter.formatWithConfidence(
                overview.content,
                confidence: overview.confidence
            )
        )
    }

    // MARK: - Phase 2: User Stories

    public func generateUserStories(input: String) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.userStories)
        do {
            let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.userStories)
            let stories = try await validationHandler.generateWithValidation(
                input: sectionContext,
                prompt: PRDPrompts.userStoriesPrompt,
                sectionName: PRDDisplayConstants.SectionNames.userStories
            )
            interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, stories.confidence))
            return PRDSection(
                title: PRDDisplayConstants.SectionNames.userStories,
                content: reportFormatter.formatWithConfidence(
                    stories.content,
                    confidence: stories.confidence
                )
            )
        } catch {
            interactionHandler.showWarning(String(format: PRDDisplayConstants.PhaseMessages.failureFormat, error.localizedDescription))
            throw error
        }
    }

    // MARK: - Phase 3: Features

    public func generateFeatures(input: String) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.features)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.featureChanges)
        let features = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: PRDPrompts.featuresPrompt,
            sectionName: PRDDisplayConstants.SectionNames.featureChanges
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, features.confidence))
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.featureChanges,
            content: reportFormatter.formatWithConfidence(
                features.content,
                confidence: features.confidence
            )
        )
    }

    // MARK: - Phase 4: Data Model

    public func generateDataModel(input: String) async throws -> PRDSection {
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.dataModel)
        let dataModelPrompt = PRDPrompts.dataModelPrompt
        let dataModel = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: dataModelPrompt,
            sectionName: PRDDisplayConstants.SectionNames.dataModel
        )
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.dataModel,
            content: reportFormatter.formatWithConfidence(
                dataModel.content,
                confidence: dataModel.confidence
            )
        )
    }

    // MARK: - Phase 5: API Operations

    public func generateAPIOperations(input: String, stack: StackContext) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.apiOperations)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.ExtendedSectionNames.apiSpecification)
        let apiPrompt = reportFormatter.enhancePromptWithStack(
            PRDPrompts.apiSpecPrompt,
            stack: stack
        )
        let apiSpec = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: apiPrompt,
            sectionName: PRDDisplayConstants.ExtendedSectionNames.apiSpecification
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, apiSpec.confidence))
        return PRDSection(
            title: PRDDisplayConstants.ExtendedSectionNames.apiSpecification,
            content: reportFormatter.formatWithStackAwareness(
                apiSpec.content,
                confidence: apiSpec.confidence
            )
        )
    }

    // MARK: - Phase 6: Test Specifications

    public func generateTestSpecifications(input: String, stack: StackContext) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.testSpecs)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.testRequirements)
        let testPrompt = reportFormatter.enhanceTestPromptWithStack(
            PRDPrompts.testSpecPrompt,
            stack: stack
        )
        let testSpec = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: testPrompt,
            sectionName: PRDDisplayConstants.SectionNames.testRequirements
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, testSpec.confidence))
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.testRequirements,
            content: reportFormatter.formatWithTestFramework(
                testSpec.content,
                confidence: testSpec.confidence,
                testFramework: stack.testFramework
            )
        )
    }

    // MARK: - Phase 7: Constraints

    public func generateConstraints(input: String, stack: StackContext) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.constraints)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.additionalConstraints)
        let stackDescription = String(
            format: PRDAnalysisConstants.StackFormatting.stackDescription,
            stack.language,
            stack.database ?? PRDDataConstants.Defaults.tbd,
            stack.security ?? PRDDataConstants.Defaults.tbd
        )
        let constraintsPrompt = reportFormatter.enhancePromptWithStack(
            PRDPrompts.constraintsPrompt,
            stack: stack
        )
        let constraints = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: constraintsPrompt,
            sectionName: PRDDisplayConstants.SectionNames.additionalConstraints
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, constraints.confidence))
        return PRDSection(
            title: PRDDisplayConstants.ExtendedSectionNames.performanceSecurityConstraints,
            content: reportFormatter.formatWithStackAwareness(
                constraints.content,
                confidence: constraints.confidence
            )
        )
    }

    // MARK: - Phase 8: Validation Criteria

    public func generateValidationCriteria(input: String) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.validation)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.successCriteria)
        let validation = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: PRDPrompts.validationPrompt,
            sectionName: PRDDisplayConstants.SectionNames.successCriteria
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, validation.confidence))
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.successCriteria,
            content: reportFormatter.formatWithClarifications(
                validation.content,
                confidence: validation.confidence,
                clarifications: validation.clarificationsNeeded
            )
        )
    }

    // MARK: - Phase 9: Technical Roadmap

    public func generateRoadmap(input: String, stack: StackContext) async throws -> PRDSection {
        interactionHandler.showProgress(PRDDisplayConstants.PhaseMessages.roadmap)
        let sectionContext = getSectionContext(for: PRDDisplayConstants.SectionNames.implementationSteps)
        let roadmapPrompt = reportFormatter.enhanceRoadmapPromptWithStack(
            PRDPrompts.roadmapPrompt,
            stack: stack
        )
        let roadmap = try await validationHandler.generateWithValidation(
            input: sectionContext,
            prompt: roadmapPrompt,
            sectionName: PRDDisplayConstants.SectionNames.implementationSteps
        )
        interactionHandler.showInfo(String(format: PRDDisplayConstants.PhaseMessages.successFormat, roadmap.confidence))
        return PRDSection(
            title: PRDDisplayConstants.ExtendedSectionNames.technicalRoadmapCICD,
            content: reportFormatter.formatWithPipeline(
                roadmap.content,
                confidence: roadmap.confidence,
                pipeline: stack.cicdPipeline
            )
        )
    }

    // MARK: - Final: Assumption Report

    public func generateAssumptionReport(assumptionTracker: AssumptionTracker) async throws -> PRDSection {
        let validationReport = try await assumptionTracker.validateAll()
        return PRDSection(
            title: PRDDisplayConstants.SectionNames.validatedAssumptions,
            content: reportFormatter.formatValidationReport(validationReport)
        )
    }
}