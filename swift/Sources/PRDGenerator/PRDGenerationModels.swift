import Foundation
import CommonModels

// MARK: - Structured PRD Generation Models using Foundation Models framework
// Note: These models require macOS 16+ and the Foundation Models framework
// They are designed for future use when the API becomes publicly available

#if canImport(FoundationModels)
import FoundationModels

// These structs would use @Generable macro when Foundation Models is available
// For now, they serve as data models for PRD generation

/// Product overview section with structured output
@available(macOS 16.0, iOS 18.1, *)
public struct ProductOverview: Equatable {
    public let executiveSummary: String
    public let problemStatement: String
    public let productVision: String
    public let strategicGoals: [String]
    public let targetMarket: String
    public let valueProposition: String

    public init(
        executiveSummary: String,
        problemStatement: String,
        productVision: String,
        strategicGoals: [String],
        targetMarket: String,
        valueProposition: String
    ) {
        self.executiveSummary = executiveSummary
        self.problemStatement = problemStatement
        self.productVision = productVision
        self.strategicGoals = strategicGoals
        self.targetMarket = targetMarket
        self.valueProposition = valueProposition
    }
}

/// Feature specification with priorities
@available(macOS 16.0, iOS 18.1, *)
public struct FeatureSpec: Equatable {
    public let name: String
    public let description: String
    public let priority: String // P0, P1, P2, P3
    public let userStories: [String]
    public let acceptanceCriteria: [String]
    public let technicalNotes: String
    public let estimatedSprintCount: Int

    public init(
        name: String,
        description: String,
        priority: String,
        userStories: [String],
        acceptanceCriteria: [String],
        technicalNotes: String,
        estimatedSprintCount: Int
    ) {
        self.name = name
        self.description = description
        self.priority = priority
        self.userStories = userStories
        self.acceptanceCriteria = acceptanceCriteria
        self.technicalNotes = technicalNotes
        self.estimatedSprintCount = estimatedSprintCount
    }
}

/// User persona definition
@available(macOS 16.0, iOS 18.1, *)
public struct UserPersona: Equatable {
    public let name: String
    public let role: String
    public let background: String
    public let goals: [String]
    public let painPoints: [String]
    public let quote: String
    public let usageFrequency: String // Daily, Weekly, Monthly, Occasional
    public let technicalLevel: String

    public init(
        name: String,
        role: String,
        background: String,
        goals: [String],
        painPoints: [String],
        quote: String,
        usageFrequency: String,
        technicalLevel: String
    ) {
        self.name = name
        self.role = role
        self.background = background
        self.goals = goals
        self.painPoints = painPoints
        self.quote = quote
        self.usageFrequency = usageFrequency
        self.technicalLevel = technicalLevel
    }
}

/// Success metric definition
@available(macOS 16.0, iOS 18.1, *)
public struct SuccessMetric: Equatable {
    public let name: String
    public let description: String
    public let baseline: String
    public let target: String
    public let measurementMethod: String
    public let reviewFrequency: String // Daily, Weekly, Monthly, Quarterly
    public let businessImpact: String

    public init(
        name: String,
        description: String,
        baseline: String,
        target: String,
        measurementMethod: String,
        reviewFrequency: String,
        businessImpact: String
    ) {
        self.name = name
        self.description = description
        self.baseline = baseline
        self.target = target
        self.measurementMethod = measurementMethod
        self.reviewFrequency = reviewFrequency
        self.businessImpact = businessImpact
    }
}

/// Technical requirements specification
@available(macOS 16.0, iOS 18.1, *)
public struct TechnicalRequirement: Equatable {
    public let category: String
    public let requirement: String
    public let rationale: String
    public let priority: String // Must Have, Should Have, Nice to Have
    public let implementationNotes: String

    public init(
        category: String,
        requirement: String,
        rationale: String,
        priority: String,
        implementationNotes: String
    ) {
        self.category = category
        self.requirement = requirement
        self.rationale = rationale
        self.priority = priority
        self.implementationNotes = implementationNotes
    }
}

/// Complete PRD structure
@available(macOS 16.0, iOS 18.1, *)
public struct GeneratedPRD: Equatable {
    public let title: String
    public let overview: ProductOverview
    public let features: [FeatureSpec]
    public let personas: [UserPersona]
    public let metrics: [SuccessMetric]
    public let technicalRequirements: [TechnicalRequirement]
    public let timeline: String
    public let riskAnalysis: String

    public init(
        title: String,
        overview: ProductOverview,
        features: [FeatureSpec],
        personas: [UserPersona],
        metrics: [SuccessMetric],
        technicalRequirements: [TechnicalRequirement],
        timeline: String,
        riskAnalysis: String
    ) {
        self.title = title
        self.overview = overview
        self.features = features
        self.personas = personas
        self.metrics = metrics
        self.technicalRequirements = technicalRequirements
        self.timeline = timeline
        self.riskAnalysis = riskAnalysis
    }
}

#endif

// MARK: - Fallback Models for systems without Foundation Models

/// Fallback PRD structure when Foundation Models is not available
public struct FallbackPRD {
    public let title: String
    public let sections: [PRDSection]
    public let metadata: [String: Any]

    public init(title: String, sections: [PRDSection], metadata: [String: Any] = [:]) {
        self.title = title
        self.sections = sections
        self.metadata = metadata
    }
}

// PRDSection is already defined in CommonModels.Protocols