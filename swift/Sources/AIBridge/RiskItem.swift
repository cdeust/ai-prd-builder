import Foundation

/// Risk item
public struct RiskItem: Codable, Equatable {
    public var name: String
    public var description: String
    public var probability: String    // Low/Medium/High
    public var impact: String         // Low/Medium/High/Critical
    public var mitigation: String
    public var owner: String?
    public var earlyWarning: String?
    
    public init(name: String, description: String, probability: String = "Medium", impact: String = "Medium", 
                mitigation: String, owner: String? = nil, earlyWarning: String? = nil) {
        self.name = name
        self.description = description
        self.probability = probability
        self.impact = impact
        self.mitigation = mitigation
        self.owner = owner
        self.earlyWarning = earlyWarning
    }
}
