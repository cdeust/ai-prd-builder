import Foundation

// MARK: - Validation Rules

public struct QuestionSpecification {
    public let requireNumbers: Bool
    public let minWords: Int
    
    public static let specifications: [String: QuestionSpecification] = [
        "deal_breakers": QuestionSpecification(requireNumbers: false, minWords: 6),
        "users_count": QuestionSpecification(requireNumbers: true, minWords: 4),
        "success_metric": QuestionSpecification(requireNumbers: true, minWords: 6)
    ]
}
