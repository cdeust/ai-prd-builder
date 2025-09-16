import Foundation
import ThinkingFramework

/// Builds YAML formatted PRD content
public struct PRDYAMLBuilder {

    // MARK: - Public Interface

    /// Add design rationale (replaces reasoning header)
    public func addReasoningHeader(_ thoughtChain: ThoughtChain?) -> String {
        guard let chain = thoughtChain else {
            return addTracabilityHeaders()
        }

        var yaml = addTracabilityHeaders()
        yaml += PRDConstants.YAMLBuilder.designRationaleSection
        yaml += PRDConstants.YAMLBuilder.evidenceSection

        // Extract key points from analysis, not the full narrative
        let evidencePoints = extractKeyEvidence(from: chain)
        for point in evidencePoints.prefix(PRDConstants.YAMLBuilder.maxEvidencePoints) {
            yaml += PRDConstants.YAMLBuilder.evidenceItemPrefix + point + PRDConstants.YAMLBuilder.newline
        }

        yaml += PRDConstants.YAMLBuilder.decisionsSection
        yaml += PRDConstants.YAMLBuilder.primaryDecision
        yaml += String(format: PRDConstants.YAMLBuilder.confidenceScoreFormat, chain.confidence)
        yaml += String(format: PRDConstants.YAMLBuilder.validationRequiredFormat, chain.assumptions.count)

        return yaml
    }

    /// Add traceability headers required for governance
    private func addTracabilityHeaders() -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: Date())

        var yaml = PRDConstants.YAMLBuilder.prdHeader
        yaml += PRDConstants.YAMLBuilder.metadataSection
        yaml += PRDConstants.YAMLBuilder.modelProviderKey + PRDConstants.YAMLBuilder.defaultModelProvider + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.modelVersionKey + PRDConstants.YAMLBuilder.defaultModelVersion + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.promptVersionKey + PRDConstants.YAMLBuilder.defaultPromptVersion + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.generatedAtKey + timestamp + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.approvedByKey + PRDConstants.YAMLBuilder.defaultApprovedBy + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.baLintKey
        yaml += PRDConstants.YAMLBuilder.baLintPassKey + PRDConstants.YAMLBuilder.defaultBaLintPass + PRDConstants.YAMLBuilder.newline
        yaml += PRDConstants.YAMLBuilder.baLintIssuesKey + PRDConstants.YAMLBuilder.defaultBaLintIssues + PRDConstants.YAMLBuilder.doubleNewline

        return yaml
    }

    /// Extract key evidence points from thought chain
    private func extractKeyEvidence(from chain: ThoughtChain) -> [String] {
        var evidence: [String] = []

        // Add high-confidence assumptions as evidence
        for assumption in chain.assumptions where assumption.confidence > 0.7 {
            evidence.append(assumption.statement)
        }

        // Add any critical observations
        for thought in chain.thoughts where thought.type == .observation {
            if let firstLine = thought.content.components(separatedBy: .newlines).first {
                evidence.append(firstLine)
            }
        }

        return evidence
    }

    /// Add overview section
    public func addOverview(_ content: String) -> String {
        return PRDConstants.YAMLKeys.overview + indentYAML(content)
    }

    /// Add features section
    public func addFeaturesHeader() -> String {
        return PRDConstants.YAMLKeys.features
    }

    /// Add a single feature
    public func addFeature(_ feature: PrioritizedFeature, details: String) -> String {
        var yaml = PRDConstants.YAMLKeys.featureItem
        yaml += PRDConstants.YAMLKeys.featureName + "\(feature.name)\n"
        yaml += String(format: PRDConstants.FeatureManagement.priorityFormat, feature.priority)
        yaml += String(format: PRDConstants.FeatureManagement.confidenceFormat, feature.confidence)
        yaml += PRDConstants.YAMLKeys.featureDetails
        yaml += indentYAML(details, level: 3)
        return yaml
    }

    /// Add API specification section
    public func addAPISpec(_ content: String) -> String {
        return PRDConstants.YAMLKeys.openAPISpec + indentYAML(content)
    }

    /// Add test specification section
    public func addTestSpec(_ content: String) -> String {
        return PRDConstants.YAMLKeys.testSpec + indentYAML(content)
    }

    /// Add technical requirements section
    public func addTechnicalRequirements(_ content: String) -> String {
        return PRDConstants.YAMLKeys.technicalReqs + indentYAML(content)
    }

    /// Add deployment section
    public func addDeployment(_ content: String) -> String {
        return PRDConstants.YAMLKeys.deployment + indentYAML(content)
    }

    /// Add validation summary
    public func addValidationSummary(
        featuresCount: Int,
        assumptionsCount: Int,
        techReqs: String,
        testSpecs: String
    ) -> String {
        var yaml = PRDConstants.YAMLKeys.validation
        yaml += PRDConstants.YAMLKeys.completenessCheck
        yaml += "    \(PRDConstants.ValidationKeys.hasOverview): true\n"
        yaml += "    \(PRDConstants.ValidationKeys.hasFeatures): true\n"
        yaml += "    \(PRDConstants.ValidationKeys.hasDeployment): true\n"
        yaml += "    \(PRDConstants.ValidationKeys.hasRequirements): \(!techReqs.isEmpty)\n"
        yaml += "    \(PRDConstants.ValidationKeys.hasTechnicalSpecs): \(!testSpecs.isEmpty)\n"
        yaml += "  \(PRDConstants.ValidationKeys.featureCount): \(featuresCount)\n"
        yaml += "  assumptions_tracked: \(assumptionsCount)\n"
        yaml += "  \(PRDConstants.ValidationKeys.readyForImplementation): true\n"

        return yaml
    }

    // MARK: - Utility Methods

    public func indentYAML(_ text: String, level: Int = 1) -> String {
        let indent = String(repeating: "  ", count: level)
        return text.split(separator: "\n")
            .map { "\(indent)\($0)" }
            .joined(separator: "\n") + "\n"
    }

    /// Convert generic text to YAML format
    public func convertToYAML(_ prd: String) -> String {
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
}
