import Foundation

/// Represents a single acceptance criterion in Given-When-Then format
public struct AcceptanceCriterion: Codable {
    public let given: String
    public let when: String
    public let then: String
    public let priority: Priority?
    public let testable: Bool?
    public let category: Category?
    
    public enum Priority: String, Codable {
        case mustHave
        case shouldHave
        case niceToHave
        case critical

        public var rawValue: String {
            switch self {
            case .mustHave:
                return AppleIntelligenceConstants.AcceptanceCriteria.Priority.mustHave
            case .shouldHave:
                return AppleIntelligenceConstants.AcceptanceCriteria.Priority.shouldHave
            case .niceToHave:
                return AppleIntelligenceConstants.AcceptanceCriteria.Priority.niceToHave
            case .critical:
                return AppleIntelligenceConstants.AcceptanceCriteria.Priority.critical
            }
        }
    }
    
    public enum Category: String, Codable {
        case functional
        case performance
        case security
        case usability
        case accessibility
        case compliance

        public var rawValue: String {
            switch self {
            case .functional:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.functional
            case .performance:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.performance
            case .security:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.security
            case .usability:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.usability
            case .accessibility:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.accessibility
            case .compliance:
                return AppleIntelligenceConstants.AcceptanceCriteria.Category.compliance
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case given, when, then, priority, testable, category
    }
    
    public init(given: String, when: String, then: String, 
                priority: Priority? = .shouldHave, 
                testable: Bool? = true,
                category: Category? = .functional) {
        self.given = given
        self.when = when
        self.then = then
        self.priority = priority
        self.testable = testable
        self.category = category
    }
}

/// Manager for acceptance criteria operations
public class AcceptanceCriteriaManager {
    
    /// Generate acceptance criteria from domain and requirements
    public static func generateCriteria(for domain: String, requirements: [String]) -> [AcceptanceCriterion] {
        // This would be enhanced with AI generation in the future
        let criteria: [AcceptanceCriterion] = []
        
        
        return criteria
    }
    
    
    /// Format acceptance criteria for display
    public static func formatCriteria(_ criteria: [AcceptanceCriterion]) -> String {
        var result = AppleIntelligenceConstants.AcceptanceCriteria.Formatting.header
        
        // Group by category
        let grouped = Dictionary(grouping: criteria) { $0.category ?? .functional }
        
        for (category, items) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            result += String(format: AppleIntelligenceConstants.AcceptanceCriteria.Formatting.categoryHeaderFormat, category.rawValue.capitalized)
            
            for (index, criterion) in items.enumerated() {
                let priority = criterion.priority?.rawValue ?? AppleIntelligenceConstants.AcceptanceCriteria.Priority.shouldHave
                let testable = criterion.testable ?? true ? AppleIntelligenceConstants.AcceptanceCriteria.Formatting.testableYes : AppleIntelligenceConstants.AcceptanceCriteria.Formatting.testableNo

                result += String(format: AppleIntelligenceConstants.AcceptanceCriteria.Formatting.criterionFormat, index + 1, priority, testable)
                result += String(format: AppleIntelligenceConstants.AcceptanceCriteria.Formatting.givenFormat, criterion.given)
                result += String(format: AppleIntelligenceConstants.AcceptanceCriteria.Formatting.whenFormat, criterion.when)
                result += String(format: AppleIntelligenceConstants.AcceptanceCriteria.Formatting.thenFormat, criterion.then)
            }
        }
        
        return result
    }
    
    /// Convert acceptance criteria to test cases format
    public static func convertToTestCases(_ criteria: [AcceptanceCriterion]) -> String {
        var result = AppleIntelligenceConstants.AcceptanceCriteria.TestGeneration.header
        
        for criterion in criteria.filter({ $0.testable ?? true }) {
            let testName = generateTestName(from: criterion)
            result += String(
                format: AppleIntelligenceConstants.AcceptanceCriteria.TestGeneration.functionTemplate,
                testName,
                criterion.given,
                criterion.when,
                criterion.then
            )
        }
        
        return result
    }
    
    private static func generateTestName(from criterion: AcceptanceCriterion) -> String {
        // Generate a test method name from the criterion
        let words = criterion.when.components(separatedBy: .whitespaces)
        return words.prefix(5).map { $0.capitalized }.joined()
    }
}
