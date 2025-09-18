import Foundation

/// Result of validating an assumption
public struct ValidationResult {
    public let assumptionId: UUID
    public let isValid: Bool
    public let confidence: Float
    public let evidence: [String]
    public let implications: String
    public let timestamp: Date

    public init(
        assumptionId: UUID,
        isValid: Bool,
        confidence: Float,
        evidence: [String],
        implications: String,
        timestamp: Date = Date()
    ) {
        self.assumptionId = assumptionId
        self.isValid = isValid
        self.confidence = confidence
        self.evidence = evidence
        self.implications = implications
        self.timestamp = timestamp
    }
}