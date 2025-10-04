import Foundation
import CommonModels
import AIProvidersCore

/// Code Archaeologist - Digs through existing codebases to understand patterns and history
public struct CodeArchaeologist {

    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Archaeological finding in the codebase
    public struct Finding {
        let artifact: String        // What was found
        let location: String        // Where (file:line)
        let age: String            // How old (based on patterns/style)
        let purpose: String        // Why it exists
        let dependencies: [String] // What depends on it
        let quality: QualityLevel
        let recommendation: String

        enum QualityLevel {
            case pristine      // Well-maintained, modern
            case functional    // Works but could be improved
            case legacy       // Old but stable
            case deprecated   // Should be replaced
            case broken      // Doesn't work properly
        }
    }

    /// Pattern discovered in the codebase
    public struct Pattern {
        let name: String
        let description: String
        let examples: [String]     // File locations
        let consistency: Float     // 0.0 to 1.0
        let recommendation: String
    }

    /// Excavate the codebase to understand its structure and patterns
    public func excavate(
        path: String,
        focus: String? = nil
    ) async throws -> ExcavationReport {

        print("\n🏺 Code Archaeologist - Beginning Excavation")
        print(String(repeating: "=", count: 50))

        // Layer 1: Surface scan - file structure and organization
        let structure = try await scanSurfaceLayer(path: path)
        print("📁 Mapped \(structure.fileCount) files in \(structure.directoryCount) directories")

        // Layer 2: Pattern recognition
        let patterns = try await identifyPatterns(
            structure: structure,
            focus: focus
        )
        print("🔍 Identified \(patterns.count) patterns")

        // Layer 3: Deep artifact analysis
        let artifacts = try await analyzeArtifacts(
            structure: structure,
            patterns: patterns,
            focus: focus
        )
        print("🏺 Analyzed \(artifacts.count) significant artifacts")

        // Layer 4: Dependency mapping
        let dependencies = try await mapDependencies(
            artifacts: artifacts
        )
        print("🕸️ Mapped \(dependencies.count) dependency chains")

        // Layer 5: Historical reconstruction
        let history = try await reconstructHistory(
            artifacts: artifacts,
            patterns: patterns
        )

        return ExcavationReport(
            timestamp: Date(),
            structure: structure,
            patterns: patterns,
            artifacts: artifacts,
            dependencies: dependencies,
            history: history,
            recommendations: generateRecommendations(
                patterns: patterns,
                artifacts: artifacts
            )
        )
    }

    public struct ExcavationReport {
        let timestamp: Date
        let structure: CodebaseStructure
        let patterns: [Pattern]
        let artifacts: [Finding]
        let dependencies: [DependencyChain]
        let history: HistoricalAnalysis
        let recommendations: [String]
    }

    public struct CodebaseStructure {
        let fileCount: Int
        let directoryCount: Int
        let primaryLanguage: String
        let frameworks: [String]
        let entryPoints: [String]
        let testCoverage: Float?
    }

    public struct DependencyChain {
        let root: String
        let chain: [String]
        let impact: String
        let risk: RiskLevel

        enum RiskLevel {
            case low
            case medium
            case high
            case critical
        }
    }

    public struct HistoricalAnalysis {
        let estimatedAge: String
        let evolutionPhases: [String]
        let technicalDebt: [String]
        let modernizationOpportunities: [String]
    }

    private func scanSurfaceLayer(path: String) async throws -> CodebaseStructure {
        let prompt = String(format: ImplementationPrompts.codebaseStructurePrompt, path) + """

        Provide concrete counts and specific findings.
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

        // Parse into CodebaseStructure
        return CodebaseStructure(
            fileCount: 0,
            directoryCount: 0,
            primaryLanguage: "Swift",
            frameworks: [],
            entryPoints: [],
            testCoverage: nil
        )
    }

    private func identifyPatterns(
        structure: CodebaseStructure,
        focus: String?
    ) async throws -> [Pattern] {
        let structureStr = String(describing: structure)
        let focusArea = focus ?? "general"
        let prompt = String(format: ImplementationPrompts.codingPatternsPrompt, structureStr, focusArea) + """

        For each pattern, provide examples and consistency score.
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

        // Parse patterns from response
        return []
    }

    private func analyzeArtifacts(
        structure: CodebaseStructure,
        patterns: [Pattern],
        focus: String?
    ) async throws -> [Finding] {
        let focusArea = focus ?? "all significant components"
        let patternsStr = patterns.map { $0.name }.joined(separator: ", ")
        let prompt = String(format: ImplementationPrompts.codeArtifactsPrompt, focusArea, patternsStr) + """

        Include file:line references.
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

        // Parse findings
        return []
    }

    private func mapDependencies(
        artifacts: [Finding]
    ) async throws -> [DependencyChain] {
        let artifactsStr = artifacts.map { $0.artifact }.joined(separator: ", ")
        let prompt = String(format: ImplementationPrompts.dependencyChainPrompt, artifactsStr) + """

        Also:
        6. Suggest decoupling strategies
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

        // Parse dependency chains
        return []
    }

    private func reconstructHistory(
        artifacts: [Finding],
        patterns: [Pattern]
    ) async throws -> HistoricalAnalysis {
        let patternsStr = patterns.map { $0.name }.joined(separator: ", ")
        let artifactsCount = String(artifacts.count)
        let prompt = String(format: ImplementationPrompts.historicalAnalysisPrompt, patternsStr, artifactsCount) + """

        Look for clues in:
        - Naming conventions changes
        - Framework version differences
        - Architectural style variations
        - Comment styles and TODOs
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

        return HistoricalAnalysis(
            estimatedAge: "Unknown",
            evolutionPhases: [],
            technicalDebt: [],
            modernizationOpportunities: []
        )
    }

    private func generateRecommendations(
        patterns: [Pattern],
        artifacts: [Finding]
    ) -> [String] {
        var recommendations: [String] = []

        // Add recommendations based on patterns and artifacts
        for pattern in patterns where pattern.consistency < 0.7 {
            recommendations.append("Standardize \(pattern.name) pattern across codebase")
        }

        for artifact in artifacts where artifact.quality == .deprecated {
            recommendations.append("Replace deprecated artifact: \(artifact.artifact)")
        }

        return recommendations
    }
}