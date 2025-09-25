import Foundation

/// Constants for display, UI, and user-facing messages
public enum PRDDisplayConstants {

    // MARK: - Section Names
    public enum SectionNames {
        public static let taskOverview = "Task Overview"
        public static let userStories = "User Stories"
        public static let featureChanges = "Feature Changes"
        public static let apiChanges = "API Changes"
        public static let testRequirements = "Test Requirements"
        public static let additionalConstraints = "Additional Constraints"
        public static let successCriteria = "Success Criteria"
        public static let implementationSteps = "Implementation Steps"
        public static let dataModel = "Data Model"
        public static let validatedAssumptions = "Validated Assumptions"
        public static let taskContext = "Task Context"
        public static let technicalStackContext = "Technical Stack & Context"
        public static let requirementsAnalysis = "Requirements Analysis & Clarifications"
    }

    // MARK: - Extended Section Names
    public enum ExtendedSectionNames {
        public static let apiSpecification = "API Endpoints Overview"
        public static let openAPISpecification = "API Endpoints & Use Cases"
        public static let performanceSecurityConstraints = "Performance, Security & Compatibility Constraints"
        public static let technicalRoadmapCICD = "Technical Roadmap & CI/CD"
        public static let assumptionValidationReport = "Assumption Validation Report"
    }

    // MARK: - Phase Messages
    public enum PhaseMessages {
        public static let generatingPRD = "\n🚀 Generating PRD..."
        public static let userStories = "  • User Stories"
        public static let features = "  • Features"
        public static let apiOperations = "  • API Operations"
        public static let testSpecs = "  • Test Specs"
        public static let constraints = "  • Constraints"
        public static let validation = "  • Validation"
        public static let roadmap = "  • Roadmap"
        public static let validatingAssumptions = "  • Validating assumptions"

        // Success messages
        public static let successFormat = "    ✓ (%d%%)"
        public static let failureFormat = "    ✗ %@"
    }

    // MARK: - Progress Messages
    public enum ProgressMessages {
        public static let analyzingRequirements = "📊 Analyzing requirements...\n"
        public static let analyzingMockupsFormat = "📐 Analyzing %d mockup(s) and requirements..."
        public static let analyzingTextOnly = "📝 Analyzing requirements..."
        public static let generatingSectionFormat = "\n🔄 Generating: %@"
        public static let sectionCompleteFormat = "✅ %@ complete"
        public static let sectionFailedFormat = "❌ %@ failed: %@"
        public static let prdComplete = "\n✅ PRD generation complete!"
        public static let overallConfidenceFormat = "Overall confidence: %d%%"
        public static let exportSuccessFormat = "✅ PRD exported to: %@"
    }

    // MARK: - Task Type Display
    public enum TaskTypeDisplay {
        public static let taskTypeFormat = "📋 Task Type: %@"
        public static let incremental = "Incremental Feature"
        public static let greenfield = "New Project"
        public static let bugFix = "Bug Fix"
        public static let refactor = "Refactoring"
        public static let configuration = "Configuration"
    }

    // MARK: - User Interaction Messages
    public enum UserInteraction {
        public static let wouldYouProvideDetails = "Would you like to provide additional details?"
        public static let provideAdditionalContext = "Please provide additional context:"
        public static let needTechnicalRequirements = "I need to understand your technical requirements better."
        public static let thankYouValidating = "Thank you! Validating your technology choices..."
        public static let wouldYouAnswerQuestion = "Would you like to answer: %@?"
        public static let wouldYouFixCompatibility = "Would you like me to fix these compatibility issues automatically?"
        public static let answerRequired = "⚠️ This is required. Please provide an answer."
        public static let yesNoPrompt = " (yes/no): "
        public static let skippingOptional = "Skipping optional question"
    }

    // MARK: - Platform Messages
    public enum PlatformMessages {
        public static let detectedPlatform = "🖥️ Detected platform: %@"
        public static let compatibilityIssues = "\n⚠️ Platform Compatibility Issues Detected:"
        public static let usingCompatibleStack = "✅ Using %@-compatible technology stack"
        public static let proceedingWithWarning = "⚠️ Proceeding with potentially incompatible stack. Some features may not work."
        public static let stackValidated = "✅ Technology stack validated for %@"
    }

    // MARK: - Error Messages
    public enum ErrorMessages {
        public static let generationError = "       ⚠️ Error during generation: %@"
        public static let errorGeneratingOverview = "Error generating overview: %@"
        public static let errorGeneratingUserStories = "Error generating user stories: %@"
        public static let mockupProcessingFailed = "⚠️ Failed to process mockups: %@"
    }

    // MARK: - Icons
    public enum Icons {
        public static let success = "✅"
        public static let failure = "❌"
        public static let warning = "⚠️"
        public static let info = "ℹ️"
        public static let analyzing = "📊"
        public static let mockup = "📐"
        public static let text = "📝"
        public static let generating = "🔄"
        public static let rocket = "🚀"
        public static let clipboard = "📋"
        public static let checkmark = "✓"
        public static let cross = "✗"
        public static let computer = "🖥️"
        public static let magnifying = "🔍"
        public static let thinking = "🤔"
        public static let red = "🔴"
    }
}