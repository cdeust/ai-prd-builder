import Foundation

/// Parser for chain of thought responses
public struct ChainOfThoughtParser {

    /// Parse assumptions from chain of thought response
    public static func parseAssumptions(from response: String, context: String) -> [Assumption] {
        var assumptions: [Assumption] = []
        let lines = response.split(separator: "\n")

        var currentAssumption: String?
        var currentConfidence: Float = ChainOfThoughtConstants.defaultConfidence
        var currentImpact: Assumption.ImpactLevel = .medium

        for line in lines {
            let lineStr = String(line)

            if lineStr.starts(with: ParserConstants.assumptionPrefix) {
                currentAssumption = lineStr.replacingOccurrences(of: ParserConstants.assumptionPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: ParserConstants.confidencePrefix) {
                let confStr = lineStr.replacingOccurrences(of: ParserConstants.confidencePrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentConfidence = Float(confStr) ?? ChainOfThoughtConstants.defaultConfidence
            } else if lineStr.starts(with: ParserConstants.impactPrefix) {
                let impactStr = lineStr.replacingOccurrences(of: ParserConstants.impactPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentImpact = parseImpactLevel(impactStr)

                // Create assumption when we have all parts
                if let assumption = currentAssumption {
                    assumptions.append(Assumption(
                        statement: assumption,
                        confidence: currentConfidence,
                        impact: currentImpact,
                        context: context
                    ))
                }
            }
        }

        return assumptions
    }

    /// Parse alternatives from response
    public static func parseAlternatives(from response: String) -> [ThoughtChain.Alternative] {
        var alternatives: [ThoughtChain.Alternative] = []

        let sections = response.split(separator: ParserConstants.approachPrefix)
        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")

            var description = ""
            var probability: Float = ChainOfThoughtConstants.defaultConfidence
            var pros: [String] = []
            var cons: [String] = []

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: ParserConstants.probabilityPrefix) {
                    let probStr = lineStr.replacingOccurrences(of: ParserConstants.probabilityPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    probability = Float(probStr) ?? ChainOfThoughtConstants.defaultConfidence
                } else if lineStr.starts(with: ParserConstants.prosPrefix) {
                    pros = [lineStr.replacingOccurrences(of: ParserConstants.prosPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)]
                } else if lineStr.starts(with: ParserConstants.consPrefix) {
                    cons = [lineStr.replacingOccurrences(of: ParserConstants.consPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)]
                } else if description.isEmpty {
                    description = lineStr
                }
            }

            if !description.isEmpty {
                alternatives.append(ThoughtChain.Alternative(
                    description: description,
                    probability: probability,
                    pros: pros,
                    cons: cons
                ))
            }
        }

        return alternatives
    }

    /// Calculate overall confidence from thoughts
    public static func calculateOverallConfidence(_ thoughts: [Thought]) -> Float {
        guard !thoughts.isEmpty else { return 0.0 }

        let totalConfidence = thoughts.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Float(thoughts.count)
    }

    // MARK: - Private Helpers

    private static func parseImpactLevel(_ str: String) -> Assumption.ImpactLevel {
        let upper = str.uppercased()
        if upper.contains(ParserConstants.criticalKeyword) { return .critical }
        if upper.contains(ParserConstants.highKeyword) { return .high }
        if upper.contains(ParserConstants.lowKeyword) { return .low }
        return .medium
    }
}