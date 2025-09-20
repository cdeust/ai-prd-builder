import Foundation

/// Constants specific to PRDGenerator operations
public enum PRDGeneratorConstants {

    // MARK: - Confidence Thresholds
    public enum Confidence {
        public static let lowThreshold = 70
        public static let highThreshold = 80
        public static let excellentThreshold = 90
        public static let maxBoostFromUser = 25
        public static let autoBoost = 15
        public static let defaultConfidence = 75
    }

    // MARK: - Limits
    public enum Limits {
        public static let maxQuestionsToAsk = 5
        public static let maxGapsToShow = 3
        public static let maxAssumptionsToShow = 10
        public static let titleMaxLength = 50
    }

    // MARK: - Display Messages
    public enum Messages {
        // Process
        public static let startingPRD = "\n📝 Interactive PRD Generation"
        public static let analyzingRequirements = "📊 Analyzing requirements...\n"

        // Stack Discovery
        public static let detectedPlatform = "🖥️ Detected platform: %@"
        public static let needsClarification = "I need to understand your technical requirements better."
        public static let validatingChoices = "Thank you! Validating your technology choices..."
        public static let techStackValidated = "✅ Technology stack validated for %@"
        public static let usingCompatibleStack = "✅ Using %@-compatible technology stack"
        public static let proceedingWithWarning = "⚠️ Proceeding with potentially incompatible stack. Some features may not work."

        // Validation
        public static let lowConfidenceDetected = "Low confidence (%d%%) detected for %@"
        public static let missingInfoHeader = "\n   Missing information:"
        public static let missingInfoItem = "   • %@"

        // Section Generation
        public static let generatingSectionFormat = "\n🔄 Generating: %@"
        public static let sectionCompleteFormat = "✅ %@ complete"
        public static let sectionFailedFormat = "❌ %@ failed: %@"

        // Completion
        public static let prdComplete = "\n✅ PRD Generation Complete!"
        public static let highQualityResult = "🎆 High quality PRD generated (%d%% confidence)"
        public static let moderateQualityResult = "ℹ️ PRD generated with moderate confidence (%d%%)"
        public static let lowQualityResult = "⚠️ PRD generated but may need review (%d%% confidence)"
    }

    // MARK: - User Interaction
    public enum UserPrompts {
        public static let provideDetails = "Would you like to provide additional details?"
        public static let additionalContext = "Please provide additional context:"
        public static let answerQuestion = "Would you like to answer: %@?"
        public static let fixCompatibility = "Would you like me to fix these compatibility issues automatically?"
    }

    // MARK: - Section Names
    public enum Sections {
        public static let technicalStack = "Technical Stack & Context"
        public static let productOverview = "Product Overview"
        public static let userStories = "User Stories"
        public static let features = "Features"
        public static let apiSpec = "OpenAPI 3.1.0 Specification"
        public static let testSpec = "Test Specifications"
        public static let constraints = "Performance, Security & Compatibility Constraints"
        public static let validation = "Validation Criteria"
        public static let roadmap = "Technical Roadmap & CI/CD"
        public static let qualityReport = "Quality Report"
    }

    // MARK: - Metadata Keys
    public enum Metadata {
        public static let generator = "PRDGenerator"
        public static let version = "5.0"
        public static let timestamp = "timestamp"
        public static let passes = "passes"
        public static let approach = "Interactive generation with validation"
        public static let confidence = "confidence"
        public static let assumptions = "assumptions"
        public static let stackAware = "stack_aware"
        public static let testFramework = "test_framework"
        public static let pipeline = "pipeline"
    }

    // MARK: - Formatting
    public enum Formatting {
        public static let bulletPoint = "   • "
        public static let andMore = "   • (and more...)"
        public static let confidenceFormat = "**Overall Confidence:** %d%%\n"
        public static let validationRateFormat = "%.1f%%"
    }
}