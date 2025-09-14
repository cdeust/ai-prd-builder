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
        case mustHave = "must-have"
        case shouldHave = "should-have"
        case niceToHave = "nice-to-have"
        case critical = "critical"
    }
    
    public enum Category: String, Codable {
        case functional = "functional"
        case performance = "performance"
        case security = "security"
        case usability = "usability"
        case accessibility = "accessibility"
        case compliance = "compliance"
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
        var result = "## Acceptance Criteria\n\n"
        
        // Group by category
        let grouped = Dictionary(grouping: criteria) { $0.category ?? .functional }
        
        for (category, items) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            result += "### \(category.rawValue.capitalized)\n\n"
            
            for (index, criterion) in items.enumerated() {
                let priority = criterion.priority?.rawValue ?? "should-have"
                let testable = criterion.testable ?? true ? "✓" : "✗"
                
                result += "\(index + 1). **[\(priority)] [Testable: \(testable)]**\n"
                result += "   - **Given:** \(criterion.given)\n"
                result += "   - **When:** \(criterion.when)\n"
                result += "   - **Then:** \(criterion.then)\n\n"
            }
        }
        
        return result
    }
    
    /// Convert acceptance criteria to test cases format
    public static func convertToTestCases(_ criteria: [AcceptanceCriterion]) -> String {
        var result = "// Generated Test Cases\n\n"
        
        for criterion in criteria.filter({ $0.testable ?? true }) {
            let testName = generateTestName(from: criterion)
            result += """
            func test\(testName)() {
                // Given: \(criterion.given)
                // TODO: Set up test data and environment
                
                // When: \(criterion.when)
                // TODO: Execute the action
                
                // Then: \(criterion.then)
                // TODO: Assert expected outcome
                XCTAssertTrue(false, "Test not implemented")
            }
            
            """
        }
        
        return result
    }
    
    private static func generateTestName(from criterion: AcceptanceCriterion) -> String {
        // Generate a test method name from the criterion
        let words = criterion.when.components(separatedBy: .whitespaces)
        return words.prefix(5).map { $0.capitalized }.joined()
    }
}
