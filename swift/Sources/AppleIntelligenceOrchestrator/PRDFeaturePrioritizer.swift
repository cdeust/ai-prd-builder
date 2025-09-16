import Foundation
import AIBridge
import ThinkingFramework

/// Handles feature prioritization using decision trees and reasoning
public struct PRDFeaturePrioritizer {

    private let decisionTree: DecisionTree
    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.decisionTree = DecisionTree(orchestrator: orchestrator)
    }

    // MARK: - Public Interface

    /// Prioritize features using decision tree analysis and validation
    public func prioritizeFeatures(_ features: [String], context: String) async throws -> [PrioritizedFeature] {
        guard !features.isEmpty else {
            return []
        }

        // First, validate each item to determine if it's a feature or persona
        let validatedFeatures = try await validateAndClassifyItems(features, context: context)

        guard !validatedFeatures.isEmpty else {
            return []
        }

        // Build decision tree for feature prioritization
        let tree = try await buildFeatureDecisionTree(features: validatedFeatures, context: context)

        // Navigate tree to get recommended priority
        let path = try await navigateDecisionTree(tree)

        // Convert to prioritized features
        return createPrioritizedFeatures(from: validatedFeatures, path: path)
    }

    /// Extract feature names from overview text
    public func extractFeatures(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        return lines
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // Skip empty lines and pure dash lines
                guard !trimmed.isEmpty && !isDashOnlyLine(trimmed) else {
                    return false
                }
                // Look for feature indicators
                return hasFeatureIndicator(trimmed)
            }
            .map { cleanFeatureName($0) }
            .filter { !$0.isEmpty && $0.count > PRDGeneratorConstants.FeatureManagement.minimumFeatureNameLength }  // Skip very short names
            .prefix(PRDConstants.FeatureManagement.maxFeaturesForEnrichment)
            .map { String($0) }
    }

    // MARK: - Private Methods

    private func isDashOnlyLine(_ line: String) -> Bool {
        // Check if line is just dashes, hyphens, or similar separators
        let cleanedLine = line.replacingOccurrences(of: " ", with: "")
        return cleanedLine.allSatisfy { PRDGeneratorConstants.Parsing.separatorCharacters.contains($0) }
    }

    private func hasFeatureIndicator(_ line: String) -> Bool {
        let lowercased = line.lowercased()

        // Check for explicit feature keywords
        if lowercased.contains("feature") || lowercased.contains("capability") {
            return true
        }

        // Check for bullet points (but not just dashes)
        for marker in ["•", "◦", "▪", "→", "*"] {
            if line.hasPrefix(marker) {
                return true
            }
        }

        // Check for numbered lists (1. 2. etc)
        if let firstChar = line.first, firstChar.isNumber {
            let pattern = "^\\d+[.)]\\s+"
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        // Check for colon-based items (but must have substantial content)
        if line.contains(":") && line.count > PRDGeneratorConstants.FeatureManagement.minimumLineLength {
            let beforeColon = line.split(separator: ":").first ?? ""
            if beforeColon.count > PRDGeneratorConstants.ArrayOperations.colonPresenceMinLength && beforeColon.count < PRDGeneratorConstants.FeatureManagement.maximumFeatureNameLength {
                return true
            }
        }

        return false
    }

    /// Use AI to validate and classify items as features or personas
    private func validateAndClassifyItems(_ items: [String], context: String) async throws -> [String] {
        let prompt = String(
            format: PRDConstants.FeatureManagement.classificationPromptTemplate,
            items.joined(separator: "\n"),
            context
        )

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .criticalAnalysis
        )

        // Parse response to extract only features
        return parseClassifiedFeatures(from: response, originalItems: items)
    }

    private func parseClassifiedFeatures(from response: String, originalItems: [String]) -> [String] {
        var features: [String] = []
        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().contains("FEATURE:") {
                // Extract the feature name after "FEATURE:"
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > PRDGeneratorConstants.ArrayOperations.minimumCount {
                    let featureName = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    if !featureName.isEmpty {
                        features.append(featureName)
                    }
                }
            }
        }

        // Fallback: if parsing fails, return original items limited to max
        if features.isEmpty {
            return Array(originalItems.prefix(PRDConstants.FeatureManagement.maxFeaturesForEnrichment))
        }

        return Array(features.prefix(PRDConstants.FeatureManagement.maxFeaturesForEnrichment))
    }

    private func buildFeatureDecisionTree(features: [String], context: String) async throws -> DecisionNode {
        let contextString = String(
            format: PRDConstants.ThinkingIntegration.productContextTemplate,
            context,
            features.joined(separator: ", ")
        )

        return try await decisionTree.buildDecisionTree(
            for: PRDConstants.ThinkingIntegration.mvpPrioritizationQuestion,
            context: contextString,
            maxDepth: PRDConstants.ThinkingIntegration.maxDecisionDepth
        )
    }

    private func navigateDecisionTree(_ tree: DecisionNode) async throws -> [DecisionNode] {
        return try await decisionTree.navigate(
            tree: tree,
            strategy: .balanced
        )
    }

    private func createPrioritizedFeatures(from features: [String], path: [DecisionNode]) -> [PrioritizedFeature] {
        return features.enumerated().map { index, name in
            let priority = calculatePriority(index: index, total: features.count)
            let confidence = calculateConfidence(priority: priority)

            return PrioritizedFeature(
                name: name,
                priority: priority,
                confidence: confidence
            )
        }
    }

    private func calculatePriority(index: Int, total: Int) -> Float {
        guard total > PRDGeneratorConstants.ArrayOperations.firstElementIndex else { return Float(PRDGeneratorConstants.FeatureManagement.defaultPriority) }
        return Float(total - index) / Float(total)
    }

    private func calculateConfidence(priority: Float) -> Float {
        return PRDConstants.ThinkingIntegration.baseFeatureConfidence +
               (priority * PRDConstants.ThinkingIntegration.confidenceMultiplier)
    }

    private func cleanFeatureName(_ line: String) -> String {
        var cleaned = line.trimmingCharacters(in: .whitespaces)

        // Remove common list markers
        for marker in PRDConstants.FeatureManagement.listMarkers {
            if cleaned.hasPrefix(marker) {
                cleaned = String(cleaned.dropFirst(marker.count))
            }
        }

        // Remove numbers (e.g., "1. ", "2) ")
        if let range = cleaned.range(of: PRDConstants.FeatureManagement.numberPattern, options: .regularExpression) {
            cleaned = String(cleaned[range.upperBound...])
        }

        // Clean up "Feature:" prefix
        if cleaned.hasPrefix(PRDConstants.FeatureManagement.featurePrefix) {
            cleaned = String(cleaned.dropFirst(PRDConstants.FeatureManagement.featurePrefix.count))
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - YAML Generation

    public func generateFeatureYAML(_ feature: PrioritizedFeature) -> String {
        var yaml = PRDConstants.YAMLKeys.featureItem
        yaml += PRDConstants.YAMLKeys.featureName + "\(feature.name)\n"
        yaml += String(format: PRDConstants.FeatureManagement.priorityFormat, feature.priority)
        yaml += String(format: PRDConstants.FeatureManagement.confidenceFormat, feature.confidence)
        return yaml
    }
}