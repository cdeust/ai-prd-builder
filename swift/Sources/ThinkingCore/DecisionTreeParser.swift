import Foundation

/// Parser for decision tree responses
public struct DecisionTreeParser {

    /// Parse options from AI response
    public static func parseOptions(from response: String) -> [OptionData] {
        var options: [OptionData] = []
        let sections = response.split(separator: ParserConstants.optionPrefix)

        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")
            var data = OptionData()

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: ParserConstants.prosPrefix) {
                    let prosStr = lineStr.replacingOccurrences(of: ParserConstants.prosPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    data.pros = prosStr.split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespaces) }
                } else if lineStr.starts(with: ParserConstants.consPrefix) {
                    let consStr = lineStr.replacingOccurrences(of: ParserConstants.consPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    data.cons = consStr.split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespaces) }
                } else if lineStr.starts(with: ParserConstants.probabilityPrefix) {
                    let probStr = lineStr.replacingOccurrences(of: ParserConstants.probabilityPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    data.probability = Float(probStr) ?? DecisionTreeConstants.defaultProbability
                } else if lineStr.starts(with: ParserConstants.riskPrefix) {
                    let riskStr = lineStr.replacingOccurrences(of: ParserConstants.riskPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    data.risk = parseRiskLevel(riskStr)
                } else if data.description.isEmpty && !lineStr.isEmpty {
                    data.description = lineStr
                }
            }

            if !data.description.isEmpty {
                options.append(data)
            }
        }

        return options
    }

    /// Convert risk level to integer value for calculations
    public static func riskValue(_ risk: DecisionNode.Option.RiskLevel) -> Int {
        switch risk {
        case .low: return DecisionTreeConstants.lowRiskValue
        case .medium: return DecisionTreeConstants.mediumRiskValue
        case .high: return DecisionTreeConstants.highRiskValue
        case .critical: return DecisionTreeConstants.criticalRiskValue
        }
    }

    /// Clean and validate follow-up question response
    public static func cleanFollowUpQuestion(_ response: String) -> String {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerCased = cleaned.lowercased()

        // Return empty if this is a final decision
        if lowerCased.contains(ParserConstants.finalKeyword) ||
           lowerCased.contains(ParserConstants.noneKeyword) {
            return ""
        }

        return cleaned
    }

    // MARK: - Private Helpers

    private static func parseRiskLevel(_ str: String) -> DecisionNode.Option.RiskLevel {
        let upper = str.uppercased()
        if upper.contains(ParserConstants.criticalKeyword) { return .critical }
        if upper.contains(ParserConstants.highKeyword) { return .high }
        if upper.contains(ParserConstants.lowKeyword) { return .low }
        return .medium
    }

    /// Temporary data structure for parsing options
    public struct OptionData {
        public var description: String = ""
        public var pros: [String] = []
        public var cons: [String] = []
        public var probability: Float = DecisionTreeConstants.defaultProbability
        public var risk: DecisionNode.Option.RiskLevel = .medium

        public init() {}
    }
}