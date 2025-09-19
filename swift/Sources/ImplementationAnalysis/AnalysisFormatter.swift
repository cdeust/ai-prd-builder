import Foundation

/// Formats implementation analysis output in the hypothesis-driven verification style
public struct AnalysisFormatter {

    /// Formats the complete implementation report in the verification style
    public static func formatReport(_ report: ImplementationAnalyzer.ImplementationReport) -> String {
        var output = """
        Timestamp: \(report.timestamp)
        Target PRD: \(report.targetPRD)

        -- Verification Phase Report --

        Hypotheses & Verification:

        """

        // Format each hypothesis with evidence
        for hypothesis in report.hypotheses {
            output += formatHypothesis(hypothesis)
        }

        // Format discrepancies
        if !report.discrepancies.isEmpty {
            output += "\nDiscrepancies Found:\n"
            for discrepancy in report.discrepancies {
                output += formatDiscrepancy(discrepancy)
            }
        }

        // Format root cause analysis
        if !report.rootCauses.isEmpty {
            output += "\n\(report.rootCauses.count). Deep Root Cause Analysis\n\n"
            for rootCause in report.rootCauses {
                output += formatRootCause(rootCause)
            }
        }

        // Format critical changes
        if !report.criticalChanges.isEmpty {
            output += "\n\(report.criticalChanges.count). Implementation Details & Rationale\n\n"
            for change in report.criticalChanges {
                output += formatCriticalChange(change)
            }
        }

        return output
    }

    private static func formatHypothesis(_ hypothesis: ImplementationAnalyzer.Hypothesis) -> String {
        var output = "Hypothesis \(hypothesis.id): \(hypothesis.statement)\n"

        // Format verification status with checkbox
        let checkbox = hypothesis.status == .confirmed ? "☑️" : "☐"
        let statusText = hypothesis.status == .confirmed ? "Confirmed" :
                        hypothesis.status == .rejected ? "Rejected" : "Partial"
        output += "- Verification: \(checkbox) \(statusText)\n"

        // Format evidence with file:line
        for evidence in hypothesis.evidence {
            output += "- Evidence: \(evidence.location)\n"
            if !evidence.snippet.isEmpty {
                output += "  \(evidence.snippet)\n"
            }
        }

        // Format findings
        if let findings = hypothesis.findings {
            output += "- Finding: \(findings)\n"
        }

        output += "\n"
        return output
    }

    private static func formatDiscrepancy(_ discrepancy: ImplementationAnalyzer.Discrepancy) -> String {
        var output = "- \(discrepancy.area) "

        if discrepancy.actual.isEmpty {
            output += "MISSING\n"
        } else {
            output += "EXISTS with issues\n"
        }

        output += "  - Expected: \(discrepancy.expected)\n"
        output += "  - Actual: \(discrepancy.actual)\n"
        output += "  - Impact: \(discrepancy.impact)\n"

        if !discrepancy.suggestedFix.isEmpty {
            output += "  - Fix: \(discrepancy.suggestedFix)\n"
        }

        output += "\n"
        return output
    }

    private static func formatRootCause(_ rootCause: ImplementationAnalyzer.RootCause) -> String {
        var output = """
        Surface Symptom: "\(rootCause.symptom)"

        Problem Chain Analysis:
        """

        // Format cause chain with checkboxes
        for (index, cause) in rootCause.chainOfCauses.enumerated() {
            let checkbox = index < rootCause.chainOfCauses.count - 1 ? "☑️" : "✖️"
            output += "\n\(index + 1). \(cause) \(checkbox)"
        }

        output += "\n\nActual Root Cause: \(rootCause.actualRoot)\n\n"

        output += """
        Why This Happened:
        - Design Decision: \(rootCause.recommendation)
        - Blind Spot: Missing universal business features
        - Reality: Building from scratch without foundation

        The Moon 🌙: \(rootCause.riskLevel)

        """

        return output
    }

    private static func formatCriticalChange(_ change: ImplementationAnalyzer.CriticalChange) -> String {
        var output = """
        CRITICAL CHANGE #\(change.id): \(change.description)

        Location: \(change.location) (\(change.oldImplementation.isEmpty ? "NEW" : "MODIFIED"))

        """

        if !change.oldImplementation.isEmpty {
            output += """
            BEFORE:
            ```swift
            \(change.oldImplementation)
            ```

            """
        }

        output += """
        \(change.oldImplementation.isEmpty ? "NEW" : "AFTER"):
        ```swift
        \(change.newImplementation)
        ```

        """

        if !change.migrationSteps.isEmpty {
            output += "MIGRATION STEPS:\n"
            for (index, step) in change.migrationSteps.enumerated() {
                output += "\(index + 1). \(step)\n"
            }
            output += "\n"
        }

        if !change.rollbackPlan.isEmpty {
            output += "ROLLBACK: \(change.rollbackPlan)\n\n"
        }

        return output
    }
}

/// Extension to format analysis phases
extension AnalysisFormatter {

    /// Formats the analysis with phase markers
    public static func formatPhase(
        _ phase: String,
        objective: String,
        status: String = "IN-PROGRESS"
    ) -> String {
        return """
        Phase: \(phase)
        Objective: \(objective)
        Status: \(status)

        """
    }

    /// Formats verification results in compact form
    public static func formatVerificationSummary(_ hypotheses: [ImplementationAnalyzer.Hypothesis]) -> String {
        var output = "Verification Summary:\n"

        let confirmed = hypotheses.filter { $0.status == .confirmed }.count
        let rejected = hypotheses.filter { $0.status == .rejected }.count
        let partial = hypotheses.filter { $0.status == .partial }.count

        output += "  ☑️ Confirmed: \(confirmed)\n"
        output += "  ☐ Rejected: \(rejected)\n"
        output += "  ⚠️ Partial: \(partial)\n"

        return output
    }
}