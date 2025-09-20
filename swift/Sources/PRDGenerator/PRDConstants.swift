import Foundation

/// Minimal constants for PRD generation - only what's actually used
public enum PRDConstants {

    // MARK: - Section Names
    public enum Sections {
        public static let productOverview = "Product Overview"
        public static let userStories = "User Stories"
        public static let features = "Features"
        public static let openAPISpec = "OpenAPI Specification"
        public static let testSpec = "Test Specifications"
        public static let constraints = "Constraints"
        public static let validationCriteria = "Validation Criteria"
        public static let technicalRoadmap = "Technical Roadmap"
    }

    // MARK: - Phase Messages
    public enum PhaseMessages {
        public static let interactivePRDGeneration = "\n📝 Interactive PRD Generation"
        public static let phase2UserStories = "\n  2️⃣ User Stories with Validation..."
        public static let phase3Features = "\n  3️⃣ Features List with Validation..."
        public static let phase4ApiSpec = "\n  4️⃣ API Endpoints Overview..."
        public static let phase5TestSpec = "\n  5️⃣ Test Specifications with Framework Context..."
        public static let phase6Constraints = "\n  6️⃣ Constraints with Stack Awareness..."
        public static let phase7Validation = "\n  7️⃣ Validation Criteria..."
        public static let phase8Roadmap = "\n  8️⃣ Technical Roadmap with CI/CD Context..."
        public static let assumptionValidation = "\n  🔍 Validating All Assumptions..."

        // Success messages
        public static let userStoriesGenerated = "     ✓ User Stories generated (Confidence: %d%%)"
        public static let userStoriesFailed = "     ✗ User Stories failed: %@"
        public static let featuresGenerated = "     ✓ Features generated (Confidence: %d%%)"
        public static let apiSpecGenerated = "     ✓ API Endpoints overview generated (Confidence: %d%%)"
        public static let testSpecGenerated = "     ✓ Test Specs generated (Confidence: %d%%)"
        public static let constraintsGenerated = "     ✓ Constraints generated (Confidence: %d%%)"
        public static let validationGenerated = "     ✓ Validation Criteria generated (Confidence: %d%%)"
        public static let roadmapGenerated = "     ✓ Roadmap generated (Confidence: %d%%)"
    }

    // MARK: - Display Messages
    public enum Messages {
        // Process
        public static let analyzingRequirements = "📊 Analyzing requirements...\n"
        public static let generatingSectionFormat = "\n🔄 Generating: %@"
        public static let sectionCompleteFormat = "✅ %@ complete"
        public static let sectionFailedFormat = "❌ %@ failed: %@"

        // Platform Detection
        public static let detectedPlatform = "🖥️ Detected platform: %@"
        public static let compatibilityIssues = "\n⚠️ Platform Compatibility Issues Detected:"
        public static let usingCompatibleStack = "✅ Using %@-compatible technology stack"
        public static let proceedingWithWarning = "⚠️ Proceeding with potentially incompatible stack. Some features may not work."
        public static let stackValidated = "✅ Technology stack validated for %@"

        // Completion
        public static let prdComplete = "\n✅ Enhanced PRD generation complete with validation!"
        public static let overallConfidence = "📊 Overall confidence: %d%%"

        // Errors
        public static let generationError = "       ⚠️ Error during generation: %@"
        public static let errorGeneratingOverview = "Error generating overview: %@"
        public static let errorGeneratingUserStories = "Error generating user stories: %@"

        // Validation
        public static let foundAssumptions = "       Found %d assumptions"
        public static let missingInfoHeader = "\n   Missing information:"
        public static let missingInfoItem = "   • %@"
        public static let lowConfidenceFormat = "Low confidence (%d%%) detected for %@"

        // User interaction
        public static let wouldYouProvideDetails = "Would you like to provide additional details?"
        public static let provideAdditionalContext = "Please provide additional context:"
        public static let needTechnicalRequirements = "I need to understand your technical requirements better."
        public static let thankYouValidating = "Thank you! Validating your technology choices..."
        public static let wouldYouAnswerQuestion = "Would you like to answer: %@?"
        public static let wouldYouFixCompatibility = "Would you like me to fix these compatibility issues automatically?"
    }

    // MARK: - Extended Section Names
    public enum ExtendedSections {
        public static let technicalStackContext = "Technical Stack & Context"
        public static let apiSpecification = "API Endpoints Overview"
        public static let openAPISpecification = "API Endpoints & Use Cases"
        public static let performanceSecurityConstraints = "Performance, Security & Compatibility Constraints"
        public static let technicalRoadmapCICD = "Technical Roadmap & CI/CD"
        public static let assumptionValidationReport = "Assumption Validation Report"
    }

    // MARK: - Content Formatting
    public enum ContentFormatting {
        public static let confidenceFormat = "\n\n**Confidence:** %d%%"
        public static let stackAwareFormat = "\n**Stack Aware:** Yes"
        public static let testFrameworkFormat = "\n**Test Framework:** %@"
        public static let pipelineFormat = "\n**Pipeline:** %@"
        public static let confidencePrefix = "**Confidence:** "
        public static let percentSuffix = "%"
        public static let additionalContextPrefix = "\n\nAdditional user context: "
        public static let prdSuffix = " - PRD"
    }

    // MARK: - Default Values
    public enum Defaults {
        public static let xctest = "XCTest"
        public static let unknown = "Unknown"
        public static let tbd = "TBD"
        public static let defaultConfidence = 75
        public static let prdGeneratorName = "PRDGenerator"
        public static let prdVersion = "4.0"
        public static let totalPasses = 8
        public static let generationApproach = "Multi-pass generation"
    }

    // MARK: - Metadata Keys
    public enum MetadataKeys {
        public static let generator = "generator"
        public static let version = "version"
        public static let timestamp = "timestamp"
        public static let passes = "passes"
        public static let approach = "approach"
    }

    // MARK: - JSON Parsing
    public enum JSONParsing {
        public static let jsonCodeBlockStart = "```json\n"
        public static let jsonCodeBlockEnd = "\n```"
        public static let confidence = "confidence"
        public static let assumptions = "assumptions"
        public static let gaps = "gaps"
        public static let recommendations = "recommendations"
    }

    // MARK: - Stack Context Formatting
    public enum StackFormatting {
        public static let stackContextTag = "\n\n<stack_context>\nLanguage: %@\nDatabase: %@\nSecurity: %@\n</stack_context>"
        public static let testContextTag = "\n\n<test_context>Test Framework: %@\n</test_context>"
        public static let cicdContextTag = "\n\n<cicd_context>\nPipeline: %@\nDeployment: %@\n</cicd_context>"
        public static let useXCTestFormat = "Use XCTest format"
        public static let useFrameworkFormat = "Use %@ format"
    }

    // MARK: - Question Parsing
    public enum QuestionParsing {
        public static let questionMark = "?"
        public static let what = "what"
        public static let which = "which"
        public static let how = "how"
        public static let should = "should"
        public static let will = "will"
        public static let dotSpace = ". "
        public static let numberPrefixes = ["1.", "2.", "3."]

        // Question keywords
        public static let languageKeywords = ["language", "programming"]
        public static let testKeywords = ["test", "testing"]
        public static let databaseKeywords = ["database", "storage", "data"]
        public static let deployKeywords = ["deploy", "pipeline", "ci/cd", "cicd", "continuous"]
        public static let securityKeywords = ["security", "compliance", "authentication", "authorization"]
        public static let performanceKeywords = ["performance", "sla", "latency", "throughput"]
        public static let integrationKeywords = ["integration", "external", "api", "third-party"]
    }

    // MARK: - Prompt Replacements
    public enum PromptReplacements {
        public static let placeholder = "%%@"
        public static let newline = "\n"
    }

    // MARK: - Confidence Thresholds
    public enum Confidence {
        public static let minimumViable = 40      // Below this, requirements are too vague
        public static let lowThreshold = 70       // Below this, needs clarification
        public static let highThreshold = 85      // Above this, high confidence
        public static let refinementNeeded = 60   // Below this, needs iterative refinement
        public static let confidenceBoostFromClarifications = 15  // Boost when clarifications provided
        public static let defaultFallback = 50    // Default confidence when parsing fails
        public static let maxClarificationsToShow = 3  // Maximum clarifications for medium confidence
    }

    // MARK: - Essential Questions
    public enum EssentialQuestions {
        public static let purposeGoal = "What is the main purpose/goal of this product?"
        public static let targetUsers = "Who are the target users?"
        public static let coreFeatures = "What are the core features (top 3-5)?"
        public static let techStack = "What technology stack should be used?"
        public static let timelineScope = "What is the expected timeline/scope?"

        public static let all = [purposeGoal, targetUsers, coreFeatures, techStack, timelineScope]
    }

    // MARK: - Weak Language Indicators
    public enum WeakLanguage {
        public static let indicators = ["might", "possibly", "could be", "maybe", "perhaps", "probably"]
    }

    // MARK: - Analysis Messages
    public enum AnalysisMessages {
        public static let analyzingCompleteness = "\n🔍 Analyzing requirements and technical stack for completeness..."
        public static let confidenceTooLow = "\n⚠️ Initial analysis confidence is too low (%d%). The requirements are too vague to generate a meaningful PRD."
        public static let clarificationIdentified = "\n🤔 I've identified some areas that need clarification for a complete PRD:"
        public static let confidenceLevels = "\n📊 **Confidence Levels:**"
        public static let requirementsConfidence = "  - Requirements: %d%%"
        public static let stackConfidence = "  - Technical Stack: %d%%"
        public static let requirementsClarificationsHeader = "\n📋 **Requirements Clarifications:**"
        public static let stackClarificationsHeader = "\n🔧 **Technical Stack Clarifications:**"
        public static let collectingClarifications = "\n📝 Let's clarify these points:"
        public static let reanalyzing = "\n🔄 Re-analyzing with provided clarifications..."
        public static let confidenceImproved = "✅ Confidence improved: %d%% → %d%%"
        public static let essentialInfoRequired = "\n🔴 **Essential Information Required:**"
        public static let cannotProceedWithoutInfo = "\nI cannot proceed without this information. Please provide answers:"
        public static let answerRequired = "⚠️ This is required. Please provide an answer."
    }
}