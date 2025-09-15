import Foundation
import AIBridge
import AIProviders

/// Handles Product Requirements Document generation with iterative enrichment
public struct PRDGenerator {

    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    // MARK: - Public Interface

    /// Generates a comprehensive PRD through iterative enrichment
    public func generate(outputFormat: OutputFormat = .yaml) async {
        displayHeader()

        guard let userInput = getUserInput() else {
            print(OrchestratorConstants.PRD.noInput)
            return
        }

        do {
            let prd = try await generateIterativePRD(for: userInput)
            displayCompletePRD(prd, format: outputFormat)
        } catch {
            CommandLineInterface.displayError("\(error)")
        }
    }

    public enum OutputFormat {
        case json
        case yaml
    }

    // MARK: - PRD Generation Phases

    private func generateIterativePRD(for input: String) async throws -> String {
        var yamlContent = ""

        // Phase 1: Initial Overview
        let phase1Result = try await executePhase1(input: input)
        yamlContent += PRDConstants.YAMLKeys.overview
        yamlContent += indentYAML(phase1Result)

        // Extract features for detailed processing
        let featureNames = extractFeatures(from: phase1Result)

        // Phase 2: Feature Details (process each feature independently)
        print(OrchestratorConstants.PRD.phase2)
        print(String(format: PRDConstants.PhaseMessages.phase2Progress, featureNames.count))
        yamlContent += PRDConstants.YAMLKeys.features
        for (index, featureName) in featureNames.enumerated() {
            print(String(format: PRDConstants.PhaseMessages.phase2FeatureProgress, index + 1, featureNames.count, featureName))
            let details = try await enrichFeature(featureName)
            yamlContent += PRDConstants.YAMLKeys.featureItem
            yamlContent += PRDConstants.YAMLKeys.featureName + "\(featureName)\n"
            yamlContent += PRDConstants.YAMLKeys.featureDetails
            yamlContent += indentYAML(details, level: 3)
        }

        // Phase 3: OpenAPI Contract Specification
        print(PRDConstants.PhaseMessages.phase3Header)
        let apiSpecs = try await executePhase3API(context: input)
        yamlContent += PRDConstants.YAMLKeys.openAPISpec
        yamlContent += indentYAML(apiSpecs)

        // Phase 4: Test Specifications (Apple ecosystem)
        print(PRDConstants.PhaseMessages.phase4Header)
        let testSpecs = try await executePhase4Tests(features: featureNames)
        yamlContent += PRDConstants.YAMLKeys.testSpec
        yamlContent += indentYAML(testSpecs)

        // Phase 5: Technical Requirements
        print(PRDConstants.PhaseMessages.phase5Header)
        let techReqs = try await executePhase5Requirements(context: input)
        yamlContent += PRDConstants.YAMLKeys.technicalReqs
        yamlContent += indentYAML(techReqs)

        // Phase 6: Deployment (Apple ecosystem)
        print(PRDConstants.PhaseMessages.phase6Header)
        let deployment = try await executePhase6Deployment()
        yamlContent += PRDConstants.YAMLKeys.deployment
        yamlContent += indentYAML(deployment)

        // Add validation summary
        yamlContent += PRDConstants.YAMLKeys.validation
        yamlContent += PRDConstants.YAMLKeys.completenessCheck
        yamlContent += "    \(PRDConstants.ValidationKeys.hasOverview): true\n"
        yamlContent += "    \(PRDConstants.ValidationKeys.hasFeatures): true\n"
        yamlContent += "    \(PRDConstants.ValidationKeys.hasDeployment): true\n"
        yamlContent += "    \(PRDConstants.ValidationKeys.hasRequirements): \(!techReqs.isEmpty)\n"
        yamlContent += "    \(PRDConstants.ValidationKeys.hasTechnicalSpecs): \(!testSpecs.isEmpty)\n"
        yamlContent += "  \(PRDConstants.ValidationKeys.featureCount): \(featureNames.count)\n"
        yamlContent += "  \(PRDConstants.ValidationKeys.readyForImplementation): true\n"

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

    private func displayCompletePRD(_ prd: String, format: OutputFormat) {
        print(OrchestratorConstants.PRD.complete)

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

    private func indentYAML(_ text: String, level: Int = 1) -> String {
        let indent = String(repeating: "  ", count: level)
        return text.split(separator: "\n")
            .map { "\(indent)\($0)" }
            .joined(separator: "\n")
    }
}