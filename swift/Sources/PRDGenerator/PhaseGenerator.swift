import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Handles generation of individual PRD phases
public final class PhaseGenerator {
    private let sectionGenerator: SectionGenerator
    private let validationHandler: ValidationHandler
    private let reportFormatter: ReportFormatter

    public init(
        provider: AIProvider,
        configuration: Configuration,
        assumptionTracker: AssumptionTracker,
        interactionHandler: UserInteractionHandler,
        sectionGenerator: SectionGenerator
    ) {
        self.sectionGenerator = sectionGenerator
        self.reportFormatter = ReportFormatter()
        self.validationHandler = ValidationHandler(
            provider: provider,
            assumptionTracker: assumptionTracker,
            interactionHandler: interactionHandler,
            sectionGenerator: sectionGenerator,
            configuration: configuration
        )
    }

    // MARK: - Phase 1: Product Overview

    public func generateProductOverview(input: String) async throws -> PRDSection {
        print(PRDDisplayConstants.PhaseMessages.generatingPRD)
        let overview = try await validationHandler.generateWithValidation(
            input: input,
            prompt: String(format: PRDPrompts.overviewPrompt, input),
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
        print(PRDDisplayConstants.PhaseMessages.userStories)
        do {
            let stories = try await validationHandler.generateWithValidation(
                input: input,
                prompt: String(format: PRDPrompts.userStoriesPrompt, input),
                sectionName: PRDDisplayConstants.SectionNames.userStories
            )
            print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, stories.confidence))
            return PRDSection(
                title: PRDDisplayConstants.SectionNames.userStories,
                content: reportFormatter.formatWithConfidence(
                    stories.content,
                    confidence: stories.confidence
                )
            )
        } catch {
            print(String(format: PRDDisplayConstants.PhaseMessages.failureFormat, error.localizedDescription))
            throw error
        }
    }

    // MARK: - Phase 3: Features

    public func generateFeatures(input: String) async throws -> PRDSection {
        print(PRDDisplayConstants.PhaseMessages.features)
        let features = try await validationHandler.generateWithValidation(
            input: input,
            prompt: String(format: PRDPrompts.featuresPrompt, input),
            sectionName: PRDDisplayConstants.SectionNames.featureChanges
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, features.confidence))
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
        let dataModelPrompt = String(format: PRDPrompts.dataModelPrompt, input)
        let dataModel = try await validationHandler.generateWithValidation(
            input: input,
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
        print(PRDDisplayConstants.PhaseMessages.apiOperations)
        let apiPrompt = reportFormatter.enhancePromptWithStack(
            String(format: PRDPrompts.apiSpecPrompt, input),
            stack: stack
        )
        let apiSpec = try await validationHandler.generateWithValidation(
            input: input,
            prompt: apiPrompt,
            sectionName: PRDDisplayConstants.ExtendedSectionNames.apiSpecification
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, apiSpec.confidence))
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
        print(PRDDisplayConstants.PhaseMessages.testSpecs)
        let testPrompt = reportFormatter.enhanceTestPromptWithStack(
            String(format: PRDPrompts.testSpecPrompt, input),
            stack: stack
        )
        let testSpec = try await validationHandler.generateWithValidation(
            input: input,
            prompt: testPrompt,
            sectionName: PRDDisplayConstants.SectionNames.testRequirements
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, testSpec.confidence))
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
        print(PRDDisplayConstants.PhaseMessages.constraints)
        let stackDescription = String(
            format: PRDAnalysisConstants.StackFormatting.stackDescription,
            stack.language,
            stack.database ?? PRDDataConstants.Defaults.tbd,
            stack.security ?? PRDDataConstants.Defaults.tbd
        )
        let constraintsPrompt = reportFormatter.enhancePromptWithStack(
            String(format: PRDPrompts.constraintsPrompt, input, stackDescription),
            stack: stack
        )
        let constraints = try await validationHandler.generateWithValidation(
            input: input,
            prompt: constraintsPrompt,
            sectionName: PRDDisplayConstants.SectionNames.additionalConstraints
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, constraints.confidence))
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
        print(PRDDisplayConstants.PhaseMessages.validation)
        let validation = try await validationHandler.generateWithValidation(
            input: input,
            prompt: String(format: PRDPrompts.validationPrompt, input),
            sectionName: PRDDisplayConstants.SectionNames.successCriteria
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, validation.confidence))
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
        print(PRDDisplayConstants.PhaseMessages.roadmap)
        let roadmapPrompt = reportFormatter.enhanceRoadmapPromptWithStack(
            PRDPrompts.roadmapPrompt,
            stack: stack
        )
        let roadmap = try await validationHandler.generateWithValidation(
            input: input,
            prompt: roadmapPrompt,
            sectionName: PRDDisplayConstants.SectionNames.implementationSteps
        )
        print(String(format: PRDDisplayConstants.PhaseMessages.successFormat, roadmap.confidence))
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