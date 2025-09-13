import Foundation

/// Generic acceptance clause
public struct AcceptanceClause: Codable, Equatable {
    public var title: String
    public var given: String
    public var when: String
    public var then: [String]
    public var performance: String?
    public var observability: [String]?
    
    public init(title: String, given: String, when: String, then: [String], performance: String? = nil, observability: [String]? = nil) {
        self.title = title
        self.given = given
        self.when = when
        self.then = then
        self.performance = performance
        self.observability = observability
    }
}
