import Foundation
import CommonModels
import AIProvidersCore
import PRDGenerator

/// Bridges PRD specifications with actual codebase implementation
/// This is the key component that maps requirements to real code
public struct PRDCodeBridge {

    private let provider: AIProvider
    private let analyzer: ImplementationAnalyzer
    private let collector = EvidenceCollector()

    public init(provider: AIProvider, projectRoot: String) {
        self.provider = provider
        self.analyzer = ImplementationAnalyzer(provider: provider, projectRoot: projectRoot)
    }

    /// Maps PRD features to actual code implementations
    public func mapPRDToCode(
        prdFeatures: [String],
        codebase: ImplementationAnalyzer.CodebaseAnalysis
    ) async throws -> FeatureMapping {

        print("\n🔗 Bridging PRD features to codebase...")

        var mappings: [FeatureCodeMap] = []

        for feature in prdFeatures {
            print("  Mapping feature: \(feature)")

            // Find related code files
            let relatedFiles = try await findRelatedFiles(
                for: feature,
                in: codebase.sourceFiles
            )

            // Determine implementation status
            let status = try await checkImplementationStatus(
                feature: feature,
                files: relatedFiles,
                codebase: codebase
            )

            mappings.append(FeatureCodeMap(
                prdFeature: feature,
                relatedFiles: relatedFiles,
                implementationStatus: status,
                requiredChanges: status.requiredChanges
            ))
        }

        return FeatureMapping(
            timestamp: Date(),
            projectRoot: codebase.projectRoot,
            featureMaps: mappings,
            overallReadiness: calculateReadiness(mappings)
        )
    }

    /// Find code files related to a PRD feature
    private func findRelatedFiles(
        for feature: String,
        in files: [String]
    ) async throws -> [RelatedFile] {

        let filesStr = files.prefix(30).joined(separator: "\n")
        let prompt = String(
            format: PRDPrompts.featureToCodeMappingPrompt,
            feature,
            filesStr
        ) + """

        Format:
        FILE: [path]
        REASON: [why this file is relevant]
        CONFIDENCE: [HIGH/MEDIUM/LOW]
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return parseRelatedFiles(from: response, allFiles: files)
    }

    /// Check if a feature is already implemented
    private func checkImplementationStatus(
        feature: String,
        files: [RelatedFile],
        codebase: ImplementationAnalyzer.CodebaseAnalysis
    ) async throws -> ImplementationStatus {

        // Scan actual code for feature implementation
        var evidenceOfImplementation: [String] = []
        var missingComponents: [String] = []

        for file in files {
            if let content = try? String(contentsOfFile: file.path) {
                // Check for feature-related code
                let hasFeatureCode = try await analyzeFileForFeature(
                    content: content,
                    feature: feature,
                    file: file.path
                )

                if hasFeatureCode.isImplemented {
                    evidenceOfImplementation.append(hasFeatureCode.evidence)
                } else {
                    missingComponents.append(hasFeatureCode.missing)
                }
            }
        }

        // Determine overall status
        if evidenceOfImplementation.isEmpty {
            return ImplementationStatus(
                status: .notStarted,
                completeness: 0.0,
                evidence: [],
                missingComponents: missingComponents,
                requiredChanges: generateRequiredChanges(for: feature)
            )
        } else if missingComponents.isEmpty {
            return ImplementationStatus(
                status: .complete,
                completeness: 1.0,
                evidence: evidenceOfImplementation,
                missingComponents: [],
                requiredChanges: []
            )
        } else {
            let completeness = Float(evidenceOfImplementation.count) /
                              Float(evidenceOfImplementation.count + missingComponents.count)
            return ImplementationStatus(
                status: .partial,
                completeness: completeness,
                evidence: evidenceOfImplementation,
                missingComponents: missingComponents,
                requiredChanges: generateRequiredChanges(for: feature)
            )
        }
    }

    private func analyzeFileForFeature(
        content: String,
        feature: String,
        file: String
    ) async throws -> (isImplemented: Bool, evidence: String, missing: String) {

        let contentPreview = String(content.prefix(1000))
        let prompt = String(
            format: PRDPrompts.codeFeatureAnalysisPrompt,
            feature,
            file,
            contentPreview
        ) + """

        Does this file contain implementation for the feature?

        Answer with:
        IMPLEMENTED: [YES/NO]
        EVIDENCE: [specific code elements if yes]
        MISSING: [what's needed if no]
        """

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        let implemented = response.contains("IMPLEMENTED: YES")
        let evidence = extractBetween(response, start: "EVIDENCE:", end: "\n") ?? ""
        let missing = extractBetween(response, start: "MISSING:", end: "\n") ?? ""

        return (implemented, evidence, missing)
    }

    private func generateRequiredChanges(for feature: String) -> [String] {
        // Generate list of changes needed to implement the feature
        return [
            "Create model for \(feature)",
            "Add service layer for \(feature)",
            "Implement API endpoints for \(feature)",
            "Add tests for \(feature)"
        ]
    }

    private func parseRelatedFiles(from response: String, allFiles: [String]) -> [RelatedFile] {
        var related: [RelatedFile] = []
        let lines = response.split(separator: "\n")

        var currentFile: String?
        var currentReason: String?
        var currentConfidence: RelatedFile.Confidence = .medium

        for line in lines {
            let lineStr = String(line)

            if lineStr.starts(with: "FILE:") {
                currentFile = lineStr.replacingOccurrences(of: "FILE:", with: "").trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: "REASON:") {
                currentReason = lineStr.replacingOccurrences(of: "REASON:", with: "").trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: "CONFIDENCE:") {
                let conf = lineStr.replacingOccurrences(of: "CONFIDENCE:", with: "").trimmingCharacters(in: .whitespaces)
                currentConfidence = conf.contains("HIGH") ? .high :
                                   conf.contains("LOW") ? .low : .medium

                // Create the related file entry
                if let file = currentFile, allFiles.contains(where: { $0.contains(file) }) {
                    related.append(RelatedFile(
                        path: allFiles.first { $0.contains(file) } ?? file,
                        reason: currentReason ?? "Related to feature",
                        confidence: currentConfidence
                    ))
                }
            }
        }

        return related
    }

    private func calculateReadiness(_ mappings: [FeatureCodeMap]) -> Float {
        guard !mappings.isEmpty else { return 0.0 }

        let totalCompleteness = mappings.reduce(0.0) { sum, map in
            sum + map.implementationStatus.completeness
        }

        return totalCompleteness / Float(mappings.count)
    }

    private func extractBetween(_ text: String, start: String, end: String) -> String? {
        guard let startRange = text.range(of: start),
              let endRange = text.range(of: end, range: startRange.upperBound..<text.endIndex) else {
            return nil
        }

        return String(text[startRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Types

    public struct FeatureMapping {
        public let timestamp: Date
        public let projectRoot: String
        public let featureMaps: [FeatureCodeMap]
        public let overallReadiness: Float

        public var summary: String {
            """
            Feature Mapping Summary:
            - Total Features: \(featureMaps.count)
            - Complete: \(featureMaps.filter { $0.implementationStatus.status == .complete }.count)
            - Partial: \(featureMaps.filter { $0.implementationStatus.status == .partial }.count)
            - Not Started: \(featureMaps.filter { $0.implementationStatus.status == .notStarted }.count)
            - Overall Readiness: \(String(format: "%.1f%%", overallReadiness * 100))
            """
        }
    }

    public struct FeatureCodeMap {
        public let prdFeature: String
        public let relatedFiles: [RelatedFile]
        public let implementationStatus: ImplementationStatus
        public let requiredChanges: [String]
    }

    public struct RelatedFile {
        public let path: String
        public let reason: String
        public let confidence: Confidence

        public enum Confidence {
            case high
            case medium
            case low
        }
    }

    public struct ImplementationStatus {
        public let status: Status
        public let completeness: Float
        public let evidence: [String]
        public let missingComponents: [String]
        public let requiredChanges: [String]

        public enum Status {
            case complete
            case partial
            case notStarted
        }
    }

    /// Generate implementation plan based on PRD and current code
    public func generateImplementationPlan(
        prd: String,
        currentCode: ImplementationAnalyzer.CodebaseAnalysis
    ) async throws -> ImplementationPlan {

        print("\n📝 Generating implementation plan...")

        // Extract features from PRD
        let features = try await extractFeaturesFromPRD(prd)

        // Map features to current code
        let mapping = try await mapPRDToCode(
            prdFeatures: features,
            codebase: currentCode
        )

        // Generate tasks for each feature
        var tasks: [ImplementationTask] = []

        for featureMap in mapping.featureMaps {
            if featureMap.implementationStatus.status != .complete {
                let task = ImplementationTask(
                    feature: featureMap.prdFeature,
                    priority: determinePriority(featureMap),
                    estimatedEffort: estimateEffort(featureMap),
                    dependencies: findDependencies(featureMap, in: mapping),
                    files: featureMap.relatedFiles.map { $0.path },
                    changes: featureMap.requiredChanges
                )
                tasks.append(task)
            }
        }

        return ImplementationPlan(
            tasks: tasks,
            mapping: mapping,
            estimatedTotalEffort: tasks.reduce(0) { $0 + $1.estimatedEffort },
            recommendedOrder: prioritizeTasks(tasks)
        )
    }

    private func extractFeaturesFromPRD(_ prd: String) async throws -> [String] {
        let prompt = String(format: PRDPrompts.extractFeaturesFromPRDPrompt, prd)

        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)
        let response: String
        switch result {
        case .success(let res):
            response = res
        case .failure(let error):
            throw error
        }

        return response.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    private func determinePriority(_ featureMap: FeatureCodeMap) -> ImplementationTask.Priority {
        if featureMap.implementationStatus.status == .notStarted {
            return .high
        } else if featureMap.implementationStatus.completeness < 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    private func estimateEffort(_ featureMap: FeatureCodeMap) -> Int {
        let baseEffort = featureMap.requiredChanges.count * 2
        let complexityMultiplier = featureMap.relatedFiles.count > 5 ? 2 : 1
        return baseEffort * complexityMultiplier
    }

    private func findDependencies(_ feature: FeatureCodeMap, in mapping: FeatureMapping) -> [String] {
        // Simple dependency detection - features that share files
        var dependencies: [String] = []

        for other in mapping.featureMaps {
            if other.prdFeature != feature.prdFeature {
                let sharedFiles = Set(feature.relatedFiles.map { $0.path })
                    .intersection(Set(other.relatedFiles.map { $0.path }))

                if !sharedFiles.isEmpty {
                    dependencies.append(other.prdFeature)
                }
            }
        }

        return dependencies
    }

    private func prioritizeTasks(_ tasks: [ImplementationTask]) -> [String] {
        // Sort by priority and dependencies
        let sorted = tasks.sorted { t1, t2 in
            if t1.priority != t2.priority {
                return t1.priority.rawValue < t2.priority.rawValue
            }
            return t1.dependencies.count < t2.dependencies.count
        }

        return sorted.map { $0.feature }
    }

    public struct ImplementationPlan {
        public let tasks: [ImplementationTask]
        public let mapping: FeatureMapping
        public let estimatedTotalEffort: Int
        public let recommendedOrder: [String]
    }

    public struct ImplementationTask {
        public let feature: String
        public let priority: Priority
        public let estimatedEffort: Int
        public let dependencies: [String]
        public let files: [String]
        public let changes: [String]

        public enum Priority: Int {
            case high = 1
            case medium = 2
            case low = 3
        }
    }
}