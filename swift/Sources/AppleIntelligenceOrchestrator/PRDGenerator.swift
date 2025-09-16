import Foundation
import AIBridge
import AIProviders
import ThinkingFramework

/// Handles Product Requirements Document generation with iterative enrichment and reasoning
public struct PRDGenerator {

    // MARK: - Components

    private let orchestrator: Orchestrator
    private let phaseExecutor: PRDPhaseExecutor
    private let assumptionManager: PRDAssumptionManager
    private let featurePrioritizer: PRDFeaturePrioritizer
    private let yamlBuilder: PRDYAMLBuilder
    private let reasoningEngine: PRDReasoningEngine

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.phaseExecutor = PRDPhaseExecutor(orchestrator: orchestrator)
        self.assumptionManager = PRDAssumptionManager(orchestrator: orchestrator)
        self.featurePrioritizer = PRDFeaturePrioritizer(orchestrator: orchestrator)
        self.yamlBuilder = PRDYAMLBuilder()
        self.reasoningEngine = PRDReasoningEngine(orchestrator: orchestrator)
    }

    // MARK: - Public Interface

    /// Generates a comprehensive PRD through iterative enrichment with reasoning
    public func generate(outputFormat: PRDOutputFormat = .yaml) async {
        displayHeader()

        guard let userInput = getUserInput() else {
            print(OrchestratorConstants.PRD.noInput)
            return
        }

        do {
            // Analyze requirements with reasoning engine
            print("\n\(ThinkingFrameworkDisplay.brainEmoji) \(PRDConstants.ThinkingIntegration.analyzingRequirements)")
            let thoughtChain = try await reasoningEngine.analyzeRequirements(userInput)

            // Generate PRD with assumption tracking
            let prd = try await generateIterativePRD(for: userInput, thoughtChain: thoughtChain)

            // Validate assumptions made during generation
            let validationReport = try await assumptionManager.validateAll()

            // Display PRD with validation insights
            displayCompletePRD(prd, validationReport: validationReport, format: outputFormat)
        } catch {
            CommandLineInterface.displayError("\(error)")
        }
    }


    // MARK: - PRD Generation Phases

    private func generateIterativePRD(for input: String, thoughtChain: ThoughtChain? = nil) async throws -> String {
        var yamlContent = ""

        // Add reasoning summary using YAML builder
        yamlContent += yamlBuilder.addReasoningHeader(thoughtChain)

        // Phase 1: Initial Overview with assumption tracking
        let phase1Result = try await executePhase1WithAssumptions(input: input, thoughtChain: thoughtChain)
        yamlContent += yamlBuilder.addOverview(phase1Result)

        // Extract and prioritize features using feature prioritizer
        let featureNames = featurePrioritizer.extractFeatures(from: phase1Result)
        let allPrioritizedFeatures = try await featurePrioritizer.prioritizeFeatures(featureNames, context: input)

        // Filter features with confidence >= threshold
        let prioritizedFeatures = allPrioritizedFeatures.filter { $0.confidence >= PRDConstants.FeatureManagement.minimumConfidenceThreshold }

        if prioritizedFeatures.count < allPrioritizedFeatures.count {
            print(String(format: PRDConstants.FeatureManagement.filteredFeaturesMessage,
                        allPrioritizedFeatures.count - prioritizedFeatures.count))
        }

        // Phase 2: Enhanced Feature Details with assumption validation
        print(OrchestratorConstants.PRD.phase2)
        print(String(format: PRDConstants.PhaseMessages.phase2Progress, prioritizedFeatures.count))
        yamlContent += yamlBuilder.addFeaturesHeader()

        for (index, feature) in prioritizedFeatures.enumerated() {
            print(String(format: PRDGeneratorConstants.PhaseMessages.phase2FeatureProgress, index + PRDGeneratorConstants.ArrayOperations.incrementValue, prioritizedFeatures.count, feature.name))

            // Track feature assumptions
            _ = assumptionManager.trackFeatureAssumption(feature, context: input)
            _ = assumptionManager.trackFeatureFeasibility(feature)

            let details = try await enrichFeatureWithReasoning(feature)
            yamlContent += yamlBuilder.addFeature(feature, details: details)
        }

        // Phase 3: OpenAPI Contract Specification
        print(PRDConstants.PhaseMessages.phase3Header)
        let apiSpecs = try await phaseExecutor.executePhase3API(context: input)
        yamlContent += yamlBuilder.addAPISpec(apiSpecs)

        // Phase 4: Test Specifications (Apple ecosystem)
        print(PRDConstants.PhaseMessages.phase4Header)
        let featureNamesForTests = prioritizedFeatures.map { $0.name }
        let testSpecs = try await phaseExecutor.executePhase4Tests(features: featureNamesForTests)
        yamlContent += yamlBuilder.addTestSpec(testSpecs)

        // Phase 5: Technical Requirements
        print(PRDConstants.PhaseMessages.phase5Header)
        let techReqs = try await phaseExecutor.executePhase5Requirements(context: input)
        yamlContent += yamlBuilder.addTechnicalRequirements(techReqs)

        // Phase 6: Deployment (Apple ecosystem)
        print(PRDConstants.PhaseMessages.phase6Header)
        let deployment = try await phaseExecutor.executePhase6Deployment()
        yamlContent += yamlBuilder.addDeployment(deployment)

        // Add validation summary and assumptions
        yamlContent += yamlBuilder.addValidationSummary(
            featuresCount: prioritizedFeatures.count,
            assumptionsCount: PRDGeneratorConstants.Assumptions.defaultAssumptionCount, // Will be updated when assumptionManager exposes count
            techReqs: techReqs,
            testSpecs: testSpecs
        )

        // Add assumptions section
        yamlContent += try await assumptionManager.generateAssumptionsYAML()

        return yamlContent
    }

    // MARK: - Phase 1: Initial Structure

    private func executePhase1(input: String) async throws -> String {
        print(OrchestratorConstants.PRD.phase1)

        let prompt = buildPhase1Prompt(input: input)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )

        return "\(PRDConstants.Phase1.sectionHeader)\(response)\(PRDConstants.Phase1.sectionFooter)"
    }

    private func buildPhase1Prompt(input: String) -> String {
        return String(format: PRDConstants.Phase1.template, input)
    }

    // MARK: - Phase 2: Feature Enrichment

    private func executePhase2(features: [String], baseDescription: String) async throws -> String {
        print(OrchestratorConstants.PRD.phase2)

        var enrichedFeatures = PRDConstants.Phase2.sectionHeader

        for feature in features {
            let details = try await enrichFeature(feature)
            enrichedFeatures += details + "\n"
        }

        return enrichedFeatures
    }

    private func enrichFeature(_ feature: String) async throws -> String {
        let prompt = String(format: PRDConstants.Phase2.template, feature)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )

        return String(format: PRDConstants.Phase2.featureHeader, feature) + response + PRDConstants.Phase2.featureFooter
    }

    // MARK: - Phase 3: API Specifications

    private func executePhase3API(context: String) async throws -> String {
        let prompt = String(format: PRDConstants.Phase3.template, context)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )
        return response
    }

    // MARK: - Phase 4: Test Specifications

    private func executePhase4Tests(features: [String]) async throws -> String {
        let featuresString = features.joined(separator: ", ")
        let prompt = String(format: PRDConstants.Phase4.template, featuresString)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )
        return response
    }

    // MARK: - Phase 5: Technical Requirements

    private func executePhase5Requirements(context: String) async throws -> String {
        let prompt = String(format: PRDConstants.Phase5.template, context)
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )
        return response
    }

    // MARK: - Phase 6: Apple Deployment

    private func executePhase6Deployment() async throws -> String {
        let prompt = PRDConstants.Phase6.template
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: PRDConstants.DefaultValues.prdThinkingMode
        )
        return response
    }

    // MARK: - Helper Methods

    private func displayHeader() {
        print(OrchestratorConstants.PRD.header)
        print(OrchestratorConstants.PRD.separator)
        print(OrchestratorConstants.PRD.prompt)
    }

    private func getUserInput() -> String? {
        print(OrchestratorConstants.UI.inputPrompt, terminator: "")
        guard let input = readLine(), !input.isEmpty else {
            return nil
        }
        return input
    }

    private func extractFeatures(from text: String) -> [String] {
        // Simple extraction - look for lines with feature indicators
        let lines = text.components(separatedBy: .newlines)
        var features: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if isFeatureLine(trimmed) {
                let feature = cleanFeatureName(trimmed)
                if !feature.isEmpty {
                    features.append(feature)
                }
            }
        }

        // Return at least some default features if none found
        return features.isEmpty ? PRDConstants.FeatureExtraction.defaultFeatures : features
    }

    private func isFeatureLine(_ line: String) -> Bool {
        return PRDConstants.FeatureExtraction.indicators.contains(where: line.hasPrefix)
    }

    private func cleanFeatureName(_ line: String) -> String {
        var cleaned = line

        for prefix in PRDConstants.FeatureExtraction.prefixesToRemove {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Handle numbered lists
        if let range = cleaned.range(of: PRDConstants.FeatureExtraction.numberedListPattern, options: .regularExpression) {
            cleaned = String(cleaned[range.upperBound...])
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private func displayCompletePRD(_ prd: String, validationReport: ValidationReport? = nil, format: PRDOutputFormat) {
        print(OrchestratorConstants.PRD.complete)

        // Display validation summary if available
        if let report = validationReport {
            print("\n\(ThinkingFrameworkDisplay.validationEmoji) Assumption Validation Summary:")
            print(report.summary)
            print("")
        }

        print(PRDConstants.OutputMessages.yamlHeader)
        print(PRDConstants.OutputMessages.separator)
        print(prd)
        print(PRDConstants.OutputMessages.separator)
        print(PRDConstants.OutputMessages.appleCompletionMessage)
    }

    private func convertToYAMLFormat(_ prd: String) -> String {
        // Simple conversion - add proper indentation and YAML markers
        let lines = prd.components(separatedBy: .newlines)
        var yamlLines: [String] = []

        for line in lines {
            if line.hasPrefix(PRDConstants.YAMLConversion.sectionPrefix) {
                // Main section
                let section = line.replacingOccurrences(of: PRDConstants.YAMLConversion.sectionPrefix, with: "")
                yamlLines.append("\(section.lowercased().replacingOccurrences(of: " ", with: PRDConstants.YAMLConversion.spaceReplacement)):")
            } else if line.hasPrefix(PRDConstants.YAMLConversion.subsectionPrefix) {
                // Subsection
                let subsection = line.replacingOccurrences(of: PRDConstants.YAMLConversion.subsectionPrefix, with: "")
                yamlLines.append("\(PRDConstants.YAMLConversion.namePrefix)\(subsection)")
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Content
                yamlLines.append("\(PRDConstants.YAMLConversion.contentIndent)\(line)")
            }
        }

        return yamlLines.joined(separator: "\n")
    }

    // MARK: - YAML Formatting Helpers

    private func indentYAML(_ text: String, level: Int = PRDGeneratorConstants.Formatting.defaultIndentLevel) -> String {
        let indent = String(repeating: "  ", count: level)
        return text.split(separator: "\n")
            .map { "\(indent)\($0)" }
            .joined(separator: "\n")
    }

    // MARK: - ThinkingFramework methods are now delegated to components

    private func executePhase1WithAssumptions(input: String, thoughtChain: ThoughtChain?) async throws -> String {
        // Track initial assumptions
        assumptionManager.trackInitialAssumptions(for: input)

        // Generate overview with enhanced reasoning if available
        let result = thoughtChain != nil
            ? try await reasoningEngine.generateEnhancedOverview(input: input, thoughtChain: thoughtChain)
            : try await phaseExecutor.executePhase1(input: input)

        // Extract additional assumptions from the overview
        try await assumptionManager.extractAssumptions(from: result)

        return result
    }

    private func enrichFeatureWithReasoning(_ feature: PrioritizedFeature) async throws -> String {
        // Delegate to phase executor
        return try await phaseExecutor.enrichFeature(feature.name)
    }
}
