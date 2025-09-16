import Foundation

/// Parser for assumption-related responses
public struct AssumptionParser {

    /// Parse assumptions from AI response
    public static func parseAssumptions(from response: String, context: String) -> [TrackedAssumption] {
        var parsedAssumptions: [TrackedAssumption] = []
        let sections = response.split(separator: ParserConstants.assumptionPrefix)

        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")
            var statement = ""
            var category: TrackedAssumption.Category = .technical
            var confidence: Float = AssumptionTrackerConstants.defaultConfidence

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: ParserConstants.categoryPrefix) {
                    let catStr = lineStr.replacingOccurrences(of: ParserConstants.categoryPrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    category = parseCategory(catStr)
                } else if lineStr.starts(with: ParserConstants.confidencePrefix) {
                    let confStr = lineStr.replacingOccurrences(of: ParserConstants.confidencePrefix, with: "")
                        .trimmingCharacters(in: .whitespaces)
                    confidence = Float(confStr) ?? AssumptionTrackerConstants.defaultConfidence
                } else if statement.isEmpty && !lineStr.isEmpty {
                    statement = lineStr
                }
            }

            if !statement.isEmpty {
                let assumption = TrackedAssumption(
                    statement: statement,
                    context: context,
                    confidence: confidence,
                    category: category
                )
                parsedAssumptions.append(assumption)
            }
        }

        return parsedAssumptions
    }

    /// Parse category from string
    public static func parseCategory(_ str: String) -> TrackedAssumption.Category {
        let upper = str.uppercased()
        if upper.contains(ParserConstants.businessCategory) { return .business }
        if upper.contains(ParserConstants.userCategory) { return .user }
        if upper.contains(ParserConstants.performanceCategory) { return .performance }
        if upper.contains(ParserConstants.securityCategory) { return .security }
        if upper.contains(ParserConstants.dataCategory) { return .data }
        return .technical
    }

    /// Parse validation result from AI response
    public static func parseValidationResult(from response: String, assumption: TrackedAssumption) -> ValidationResult {
        let lines = response.split(separator: "\n")
        var isValid = false
        var confidence: Float = AssumptionTrackerConstants.defaultConfidence
        var evidence: [String] = []
        var implications = ""

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: ParserConstants.validPrefix) {
                let validStr = lineStr.replacingOccurrences(of: ParserConstants.validPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                isValid = validStr.contains(ParserConstants.yesKeyword)
            } else if lineStr.starts(with: ParserConstants.evidencePrefix) {
                let evidenceStr = lineStr.replacingOccurrences(of: ParserConstants.evidencePrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                evidence = [evidenceStr]
            } else if lineStr.starts(with: ParserConstants.confidencePrefix) {
                let confStr = lineStr.replacingOccurrences(of: ParserConstants.confidencePrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                confidence = Float(confStr) ?? AssumptionTrackerConstants.defaultConfidence
            } else if lineStr.starts(with: ParserConstants.implicationsPrefix) {
                implications = lineStr.replacingOccurrences(of: ParserConstants.implicationsPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return ValidationResult(
            assumptionId: assumption.id,
            isValid: isValid,
            confidence: confidence,
            evidence: evidence,
            implications: implications
        )
    }

    /// Parse impact assessment from AI response
    public static func parseImpactAssessment(from response: String) -> TrackedAssumption.ImpactAssessment {
        let lines = response.split(separator: "\n")
        var scope: TrackedAssumption.ImpactAssessment.ImpactScope = .local
        var severity: TrackedAssumption.ImpactAssessment.Severity = .low
        var affected: [String] = []
        var mitigation: String?

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: ParserConstants.scopePrefix) {
                let scopeStr = lineStr.replacingOccurrences(of: ParserConstants.scopePrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                scope = scopeStr.contains(ParserConstants.criticalKeyword) ? .critical :
                       scopeStr.contains(ParserConstants.systemKeyword) ? .system :
                       scopeStr.contains(ParserConstants.moduleKeyword) ? .module : .local
            } else if lineStr.starts(with: ParserConstants.severityPrefix) {
                let sevStr = lineStr.replacingOccurrences(of: ParserConstants.severityPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                severity = sevStr.contains(ParserConstants.criticalKeyword) ? .critical :
                          sevStr.contains(ParserConstants.highKeyword) ? .high :
                          sevStr.contains(ParserConstants.mediumKeyword) ? .medium : .low
            } else if lineStr.starts(with: ParserConstants.affectedPrefix) {
                let affStr = lineStr.replacingOccurrences(of: ParserConstants.affectedPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                affected = affStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            } else if lineStr.starts(with: ParserConstants.mitigationPrefix) {
                mitigation = lineStr.replacingOccurrences(of: ParserConstants.mitigationPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return TrackedAssumption.ImpactAssessment(
            scope: scope,
            severity: severity,
            affectedComponents: affected,
            mitigation: mitigation
        )
    }

    /// Parse contradictions from AI response
    public static func parseContradictions(from response: String) -> [Contradiction] {
        // Simplified implementation - could be enhanced
        return []
    }
}