import Foundation

/// Report summarizing validation results
public struct ValidationReport {
    public let timestamp: Date
    public let totalAssumptions: Int
    public let validated: Int
    public let valid: Int
    public let invalid: Int
    public let results: [ValidationResult]

    public init(
        timestamp: Date = Date(),
        totalAssumptions: Int,
        validated: Int,
        valid: Int,
        invalid: Int,
        results: [ValidationResult]
    ) {
        self.timestamp = timestamp
        self.totalAssumptions = totalAssumptions
        self.validated = validated
        self.valid = valid
        self.invalid = invalid
        self.results = results
    }

    public var summary: String {
        let validPercentage = calculateValidPercentage()
        let unverified = totalAssumptions - validated

        return """
        Validation Report:
        - Total Assumptions: \(totalAssumptions)
        - Validated: \(validated)
        - Valid: \(valid) (\(formatPercentage(validPercentage)))
        - Invalid: \(invalid)
        - Unverified: \(unverified)
        """
    }

    private func calculateValidPercentage() -> Float {
        guard validated > 0 else { return 0 }
        return Float(valid) / Float(validated) * AssumptionTrackerConstants.validPercentageMultiplier
    }

    private func formatPercentage(_ percentage: Float) -> String {
        return String(format: "%.1f%%", percentage)
    }
}