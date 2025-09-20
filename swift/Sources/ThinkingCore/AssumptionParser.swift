import Foundation

/// Parser for assumption-related responses
public struct AssumptionParser {

    /// Parse assumptions from AI response
    public static func parseAssumptions(from response: String, context: String) -> [TrackedAssumption] {
        var parsedAssumptions: [TrackedAssumption] = []

        // Try both formats: numbered list format and ASSUMPTION: format
        if response.contains("**Assumption:**") || response.contains("Assumption:") {
            parsedAssumptions = parseNumberedFormat(from: response, context: context)
        }

        if parsedAssumptions.isEmpty {
            // Fallback to original format
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
        }

        return parsedAssumptions
    }

    /// Parse numbered assumption format from Apple Intelligence
    private static func parseNumberedFormat(from response: String, context: String) -> [TrackedAssumption] {
        var assumptions: [TrackedAssumption] = []

        // Split by numbered items (1., 2., etc.)
        let pattern = "\\d+\\."
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(response.startIndex..., in: response)
        let matches = regex?.matches(in: response, options: [], range: nsRange) ?? []

        for i in 0..<matches.count {
            let startRange = matches[i].range

            // Calculate the end position
            let startIndex = response.index(response.startIndex, offsetBy: startRange.upperBound)
            let endIndex: String.Index

            if i < matches.count - 1 {
                // Next match exists, use its location as the end
                endIndex = response.index(response.startIndex, offsetBy: matches[i + 1].range.location)
            } else {
                // Last match, use end of string
                endIndex = response.endIndex
            }

            let section = String(response[startIndex..<endIndex])

            if let assumption = parseAssumptionSection(section, context: context) {
                assumptions.append(assumption)
            }
        }

        return assumptions
    }

    /// Parse a single assumption section
    private static func parseAssumptionSection(_ section: String, context: String) -> TrackedAssumption? {
        var statement = ""
        var category: TrackedAssumption.Category = .technical
        var confidence: Float = AssumptionTrackerConstants.defaultConfidence

        let lines = section.split(separator: "\n")

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            // Extract statement (after **Assumption:** or Assumption:)
            if lineStr.contains("**Assumption:**") {
                statement = lineStr.replacingOccurrences(of: "**Assumption:**", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if lineStr.contains("Assumption:") && statement.isEmpty {
                statement = lineStr.replacingOccurrences(of: "Assumption:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }

            // Extract category
            if lineStr.contains("**Category:**") {
                let catStr = lineStr.replacingOccurrences(of: "**Category:**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                category = parseCategory(catStr)
            } else if lineStr.contains("Category:") {
                let catStr = lineStr.replacingOccurrences(of: "Category:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                category = parseCategory(catStr)
            }

            // Extract confidence
            if lineStr.contains("**Confidence:**") {
                let confStr = lineStr.replacingOccurrences(of: "**Confidence:**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                confidence = Float(confStr) ?? AssumptionTrackerConstants.defaultConfidence
            } else if lineStr.contains("Confidence:") {
                let confStr = lineStr.replacingOccurrences(of: "Confidence:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                confidence = Float(confStr) ?? AssumptionTrackerConstants.defaultConfidence
            }
        }

        guard !statement.isEmpty else { return nil }

        return TrackedAssumption(
            statement: statement,
            context: context,
            confidence: confidence,
            category: category
        )
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
            implications: implications,
            timestamp: Date()
        )
    }

    /// Parse impact assessment from AI response
    public static func parseImpactAssessment(from response: String) -> TrackedAssumption.ImpactAssessment {
        let lines = response.split(separator: "\n")
        var scope: TrackedAssumption.ImpactAssessment.ImpactScope = .module
        var severity: TrackedAssumption.ImpactAssessment.Severity = .medium
        var areas: [String] = []
        var mitigation = ""

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: ParserConstants.scopePrefix) {
                let scopeStr = lineStr.replacingOccurrences(of: ParserConstants.scopePrefix, with: "")
                    .trimmingCharacters(in: .whitespaces).uppercased()
                scope = parseScope(scopeStr)
            } else if lineStr.starts(with: ParserConstants.severityPrefix) {
                let sevStr = lineStr.replacingOccurrences(of: ParserConstants.severityPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces).uppercased()
                severity = parseSeverity(sevStr)
            } else if lineStr.starts(with: ParserConstants.affectedPrefix) {
                let areasStr = lineStr.replacingOccurrences(of: ParserConstants.affectedPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                areas = areasStr.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            } else if lineStr.starts(with: ParserConstants.mitigationPrefix) {
                mitigation = lineStr.replacingOccurrences(of: ParserConstants.mitigationPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return TrackedAssumption.ImpactAssessment(
            scope: scope,
            severity: severity,
            affectedComponents: areas,
            mitigation: mitigation.isEmpty ? nil : mitigation
        )
    }

    /// Parse contradictions from AI response
    public static func parseContradictions(from response: String) -> [Contradiction] {
        var contradictions: [Contradiction] = []

        // Look for contradiction patterns in the response
        let lines = response.split(separator: "\n")
        var currentContradiction: (assumption1: UUID?, assumption2: UUID?, conflict: String?, resolution: String?)?

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.contains("CONTRADICTION:") || lineStr.contains("Contradiction:") {
                // Start new contradiction
                if let current = currentContradiction,
                   let a1 = current.assumption1,
                   let a2 = current.assumption2,
                   let conflict = current.conflict,
                   let resolution = current.resolution {
                    contradictions.append(Contradiction(
                        assumption1: a1,
                        assumption2: a2,
                        conflict: conflict,
                        resolution: resolution
                    ))
                }
                currentContradiction = (nil, nil, nil, nil)
            } else if lineStr.contains("ASSUMPTION1:") || lineStr.contains("Assumption 1:") {
                let idStr = lineStr.replacingOccurrences(of: "ASSUMPTION1:", with: "")
                    .replacingOccurrences(of: "Assumption 1:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContradiction?.assumption1 = UUID(uuidString: idStr) ?? UUID()
            } else if lineStr.contains("ASSUMPTION2:") || lineStr.contains("Assumption 2:") {
                let idStr = lineStr.replacingOccurrences(of: "ASSUMPTION2:", with: "")
                    .replacingOccurrences(of: "Assumption 2:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentContradiction?.assumption2 = UUID(uuidString: idStr) ?? UUID()
            } else if lineStr.contains("CONFLICT:") || lineStr.contains("Conflict:") {
                currentContradiction?.conflict = lineStr
                    .replacingOccurrences(of: "CONFLICT:", with: "")
                    .replacingOccurrences(of: "Conflict:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if lineStr.contains("RESOLUTION:") || lineStr.contains("Resolution:") {
                currentContradiction?.resolution = lineStr
                    .replacingOccurrences(of: "RESOLUTION:", with: "")
                    .replacingOccurrences(of: "Resolution:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        // Add last contradiction if exists
        if let current = currentContradiction,
           let a1 = current.assumption1,
           let a2 = current.assumption2,
           let conflict = current.conflict,
           let resolution = current.resolution {
            contradictions.append(Contradiction(
                assumption1: a1,
                assumption2: a2,
                conflict: conflict,
                resolution: resolution
            ))
        }

        return contradictions
    }

    /// Parse alternative option from AI response
    public static func parseAlternativeOption(from response: String) -> AlternativeOption? {
        let lines = response.split(separator: "\n")
        var description = ""
        var pros: [String] = []
        var cons: [String] = []
        var probability: Float = 0.5

        for line in lines {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)

            if lineStr.starts(with: ParserConstants.optionPrefix) {
                description = lineStr.replacingOccurrences(of: ParserConstants.optionPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: ParserConstants.prosPrefix) {
                let prosStr = lineStr.replacingOccurrences(of: ParserConstants.prosPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                pros = prosStr.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
            } else if lineStr.starts(with: ParserConstants.consPrefix) {
                let consStr = lineStr.replacingOccurrences(of: ParserConstants.consPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                cons = consStr.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
            } else if lineStr.starts(with: ParserConstants.probabilityPrefix) {
                let probStr = lineStr.replacingOccurrences(of: ParserConstants.probabilityPrefix, with: "")
                    .trimmingCharacters(in: .whitespaces)
                probability = Float(probStr) ?? 0.5
            }
        }

        guard !description.isEmpty else { return nil }

        return AlternativeOption(
            description: description,
            pros: pros,
            cons: cons,
            probabilityOfSuccess: probability
        )
    }

    // MARK: - Private Helper Methods

    private static func parseScope(_ str: String) -> TrackedAssumption.ImpactAssessment.ImpactScope {
        if str.contains(ParserConstants.systemKeyword) { return .system }
        if str.contains(ParserConstants.criticalKeyword) { return .critical }
        return .module
    }

    private static func parseSeverity(_ str: String) -> TrackedAssumption.ImpactAssessment.Severity {
        if str.contains(ParserConstants.criticalKeyword) { return .critical }
        if str.contains(ParserConstants.highKeyword) { return .high }
        if str.contains(ParserConstants.lowKeyword) { return .low }
        return .medium
    }
}