import Foundation
import CommonModels

/// Generates alternative approaches when confidence is low
public final class AlternativeGenerator {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Generate alternatives for a low-confidence response
    public func generateAlternatives(
        for originalResponse: String,
        context: String,
        confidence: Int,
        count: Int = 3
    ) async throws -> [AlternativeOption] {
        let prompt = buildAlternativesPrompt(
            originalResponse: originalResponse,
            context: context,
            confidence: confidence,
            count: count
        )

        let messages = [
            ChatMessage(role: .system, content: AlternativeGeneratorConstants.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)

        switch result {
        case .success(let response):
            return parseAlternatives(from: response)
        case .failure(let error):
            print("Failed to generate alternatives: \(error)")
            return []
        }
    }

    /// Evaluate and rank alternatives
    public func evaluateAlternatives(_ alternatives: [AlternativeOption]) -> [AlternativeOption] {
        // Sort by score (highest first)
        return alternatives.sorted(by: >)
    }

    /// Select the best alternative based on criteria
    public func selectBestAlternative(
        from alternatives: [AlternativeOption],
        preferLowRisk: Bool = false,
        preferQuickWins: Bool = false
    ) -> AlternativeOption? {
        guard !alternatives.isEmpty else { return nil }

        if preferLowRisk {
            // Filter for low risk options first
            let lowRiskOptions = alternatives.filter {
                $0.riskLevel == .minimal || $0.riskLevel == .low
            }
            if !lowRiskOptions.isEmpty {
                return lowRiskOptions.max(by: { $0.score < $1.score })
            }
        }

        if preferQuickWins {
            // Filter for low effort options
            let quickWins = alternatives.filter {
                $0.estimatedEffort == .trivial || $0.estimatedEffort == .low
            }
            if !quickWins.isEmpty {
                return quickWins.max(by: { $0.score < $1.score })
            }
        }

        // Default: return highest scoring alternative
        return alternatives.max(by: { $0.score < $1.score })
    }

    // MARK: - Private Methods

    private func buildAlternativesPrompt(
        originalResponse: String,
        context: String,
        confidence: Int,
        count: Int
    ) -> String {
        return """
        The following response has low confidence (\(confidence)%):

        ORIGINAL RESPONSE:
        \(originalResponse)

        CONTEXT:
        \(context)

        Generate \(count) alternative approaches to address this problem. For each alternative:

        1. Provide a clear description of the approach
        2. List specific pros (advantages)
        3. List specific cons (disadvantages)
        4. Estimate probability of success (0.0 to 1.0)
        5. Estimate effort level (Trivial/Low/Medium/High/Very High)
        6. Assess risk level (Minimal/Low/Moderate/High/Critical)

        Format each alternative as:
        ALTERNATIVE [number]:
        DESCRIPTION: [description]
        PROS: [pro1]; [pro2]; [pro3]
        CONS: [con1]; [con2]; [con3]
        PROBABILITY: [0.0-1.0]
        EFFORT: [level]
        RISK: [level]

        Focus on practical, implementable alternatives that address the core requirements.
        """
    }

    private func parseAlternatives(from response: String) -> [AlternativeOption] {
        var alternatives: [AlternativeOption] = []

        // Split by alternative markers
        let sections = response.split(separator: "ALTERNATIVE")

        for section in sections.dropFirst() {
            if let alternative = parseAlternativeSection(String(section)) {
                alternatives.append(alternative)
            }
        }

        return alternatives
    }

    private func parseAlternativeSection(_ section: String) -> AlternativeOption? {
        var description = ""
        var pros: [String] = []
        var cons: [String] = []
        var probability: Float = 0.5
        var effort: AlternativeOption.EffortLevel?
        var risk: AlternativeOption.RiskLevel?

        let lines = section.split(separator: "\n")

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: "DESCRIPTION:") {
                description = lineStr.replacingOccurrences(of: "DESCRIPTION:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: "PROS:") {
                let prosStr = lineStr.replacingOccurrences(of: "PROS:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                pros = prosStr.split(separator: ";").map {
                    String($0.trimmingCharacters(in: .whitespaces))
                }
            } else if lineStr.starts(with: "CONS:") {
                let consStr = lineStr.replacingOccurrences(of: "CONS:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                cons = consStr.split(separator: ";").map {
                    String($0.trimmingCharacters(in: .whitespaces))
                }
            } else if lineStr.starts(with: "PROBABILITY:") {
                let probStr = lineStr.replacingOccurrences(of: "PROBABILITY:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                probability = Float(probStr) ?? 0.5
            } else if lineStr.starts(with: "EFFORT:") {
                let effortStr = lineStr.replacingOccurrences(of: "EFFORT:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                effort = parseEffortLevel(effortStr)
            } else if lineStr.starts(with: "RISK:") {
                let riskStr = lineStr.replacingOccurrences(of: "RISK:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                risk = parseRiskLevel(riskStr)
            }
        }

        guard !description.isEmpty else { return nil }

        return AlternativeOption(
            description: description,
            pros: pros,
            cons: cons,
            probabilityOfSuccess: probability,
            estimatedEffort: effort,
            riskLevel: risk
        )
    }

    private func parseEffortLevel(_ str: String) -> AlternativeOption.EffortLevel? {
        let lower = str.lowercased()
        if lower.contains("trivial") { return .trivial }
        if lower.contains("very high") { return .veryHigh }
        if lower.contains("high") { return .high }
        if lower.contains("medium") { return .medium }
        if lower.contains("low") { return .low }
        return nil
    }

    private func parseRiskLevel(_ str: String) -> AlternativeOption.RiskLevel? {
        let lower = str.lowercased()
        if lower.contains("critical") { return .critical }
        if lower.contains("minimal") { return .minimal }
        if lower.contains("moderate") { return .moderate }
        if lower.contains("high") { return .high }
        if lower.contains("low") { return .low }
        return nil
    }
}

// MARK: - Constants
private enum AlternativeGeneratorConstants {
    static let systemPrompt = """
    You are an expert problem solver tasked with generating alternative approaches
    when the initial solution has low confidence. Focus on:
    1. Practical, implementable solutions
    2. Clear trade-offs between alternatives
    3. Realistic assessment of effort and risk
    4. Evidence-based probability estimates
    """
}