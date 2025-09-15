import Foundation
import AIBridge

/// Constants for PRD generation prompts and templates
public enum PRDConstants {

    // MARK: - Phase 1 Prompts

    public enum Phase1 {
        public static let template = """
        Create a basic Product Requirements Document for: %@

        Focus on:
        1. Product vision (1-2 sentences)
        2. List of main features (just names, we'll detail them later)
        3. Target users (brief)
        4. High-level architecture type

        Keep it concise - this is just the skeleton.
        """

        public static let sectionHeader = "## INITIAL OVERVIEW\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Phase 2 Feature Enrichment

    public enum Phase2 {
        public static let template = """
        For the feature '%@', provide:

        1. User story (As a... I want... So that...)
        2. Specific test data examples (concrete values, not placeholders)
        3. Clear acceptance criteria (specific, measurable conditions)
        4. Edge cases to consider

        Be specific and concrete. Provide actual test values.
        Focus only on this specific feature.
        """

        public static let sectionHeader = "## DETAILED FEATURES\n\n"
        public static let featureHeader = "### %@\n"
        public static let featureFooter = "\n"
    }

    // MARK: - Phase 3 API Specifications

    public enum Phase3 {
        public static let template = """
        Create a valid OpenAPI 3.1.0 specification for: %@

        CRITICAL OpenAPI structure rules:

        1. Root level keys (all at same level):
           - openapi: "3.1.0"
           - info: object with title, version, description (NO servers here!)
           - servers: array at ROOT with url (NOT baseUrl) and description
           - paths: endpoints grouped by path
           - components: contains schemas AND securitySchemes
           - security: array of security requirements

        2. Common mistakes to AVOID:
           - DO NOT nest servers under info
           - DO NOT put securitySchemes at root level
           - DO NOT give GET operations a requestBody
           - DO NOT forget requestBody for POST/PUT/PATCH
           - DO NOT duplicate security definitions

        3. Paths structure:
           - All methods (get, post, put, delete) under same path
           - Each operation needs responses with proper schemas
           - Reference schemas using $ref: '#/components/schemas/ModelName'

        4. REST conventions:
           - GET: retrieve, query params only, NO body
           - POST/PUT/PATCH: create/update, MUST have requestBody
           - DELETE: remove, typically no body

        Ensure valid YAML that validates with OpenAPI tools.
        """

        public static let simpleTemplate = """
        Based on the project: %@

        Provide technical specifications:
        1. API endpoints needed
        2. Database schema
        3. Key algorithms
        4. Third-party integrations

        Be concise and specific.
        """

        public static let sectionHeader = "## API SPECIFICATIONS\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Phase 4 Apple Test Specifications

    public enum Phase4 {
        public static let template = """
        Create test specifications for Apple ecosystem for features: %@

        Requirements:
        1. Unit Tests (XCTest):
           - Test individual components and functions
           - Use async/await for asynchronous tests
           - Mock dependencies appropriately
           - Follow Given-When-Then pattern

        2. Performance Tests:
           - Use measure() blocks for performance testing
           - Use XCTOSSignpostMetric for detailed performance analysis
           - Set baseline metrics and tolerances
           - Test critical paths and bottlenecks

        3. Integration Tests:
           - Test component interactions
           - Verify data flow between modules
           - Test with real (test) data when appropriate

        Notes:
        - UI tests now use recorded interactions in Xcode 16+
        - Focus on testable business logic
        - Ensure tests are deterministic and isolated
        """

        public static let sectionHeader = "## TEST SPECIFICATIONS (APPLE ECOSYSTEM)\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Phase 5 Technical Requirements

    public enum Phase5 {
        public static let template = """
        Define technical requirements for: %@

        Include:
        1. Platform requirements:
           - iOS deployment target (e.g., iOS 17.0+)
           - macOS deployment target (e.g., macOS 14.0+)
           - watchOS/tvOS/visionOS if applicable
           - Minimum SDK versions

        2. Development environment:
           - Xcode version required
           - Swift version (e.g., Swift 5.9)
           - Swift Concurrency requirements

        3. Apple frameworks and technologies:
           - SwiftUI/UIKit requirements
           - Core frameworks (Foundation, Combine, Core Data, etc.)
           - Apple-specific features (CloudKit, Sign in with Apple, etc.)

        4. Performance requirements:
           - Launch time: cold start < 400ms (p95), warm < 200ms
           - Memory usage: < 50MB baseline, < 150MB peak (p95)
           - Battery impact: minimal background activity
           - Network: implement retry logic, handle offline mode
           - Response times: API calls < 2s (p95)
           - Error handling: graceful degradation, clear error states

        5. Apple Human Interface Guidelines compliance:
           - Design system requirements
           - Accessibility standards (VoiceOver, Dynamic Type)
           - Platform-specific UI conventions

        6. Security and privacy:
           - Keychain Services for sensitive data
           - Biometric authentication (Face ID/Touch ID)
           - App Transport Security requirements
           - Privacy manifest requirements

        Be specific with platform SDK versions and realistic performance targets.
        """

        public static let sectionHeader = "## TECHNICAL REQUIREMENTS\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Phase 6 Apple Deployment

    public enum Phase6 {
        public static let template = """
        Create Apple deployment configuration:

        1. TestFlight setup
           - Beta testing groups
           - Build distribution
        2. App Store Connect
           - App metadata
           - Screenshots requirements
        3. Xcode Cloud CI/CD
           - Build workflows
           - Test actions
        4. Code signing
           - Certificates
           - Provisioning profiles
        5. Environment configuration
           - Development
           - Staging
           - Production

        Be specific about Apple ecosystem requirements.
        """

        public static let sectionHeader = "## APPLE DEPLOYMENT\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Feature Extraction

    public enum FeatureExtraction {
        public static let defaultFeatures = [
            "Core Functionality",
            "User Management",
            "Data Processing"
        ]

        public static let indicators = [
            "- ", "* ", "• ", "Feature:", "→",
            "1.", "2.", "3.", "4.", "5."
        ]

        public static let prefixesToRemove = [
            "- ", "* ", "• ", "Feature:", "→ "
        ]

        public static let numberedListPattern = #"^\d+\.\s*"#
    }

    // MARK: - YAML Conversion

    public enum YAMLConversion {
        public static let sectionPrefix = "## "
        public static let subsectionPrefix = "### "
        public static let namePrefix = "  - name: "
        public static let contentIndent = "    "
        public static let spaceReplacement = "_"
    }

    // MARK: - YAML Structure Keys

    public enum YAMLKeys {
        public static let overview = "overview: |\n"
        public static let features = "\nfeatures:\n"
        public static let featureItem = "  -\n"
        public static let featureName = "    name: "
        public static let featureDetails = "    details: |\n"
        public static let openAPISpec = "\nopenapi_specification: |\n"
        public static let testSpec = "\ntest_specifications: |\n"
        public static let technicalReqs = "\ntechnical_requirements: |\n"
        public static let deployment = "\ndeployment: |\n"
        public static let validation = "\nvalidation:\n"
        public static let completenessCheck = "  completeness_check:\n"
    }

    // MARK: - Output Messages

    public enum OutputMessages {
        public static let jsonHeader = "\n📄 PRD Generated in JSON Format:"
        public static let yamlHeader = "\n📄 PRD Generated in YAML Format:"
        public static let separator = String(repeating: "=", count: 60)
        public static let completionMessage = "\n✅ PRD ready for implementation by any GenAI model"
        public static let appleCompletionMessage = "\n📱 Ready for Apple ecosystem implementation"
    }

    // MARK: - Phase Progress Messages

    public enum PhaseMessages {
        public static let phase2Progress = "Processing %d features..."
        public static let phase2FeatureProgress = "  [%d/%d] Enriching: %@"
        public static let phase3Header = "\n🌐 Phase 3: Creating OpenAPI contract specification..."
        public static let phase4Header = "\n🧪 Phase 4: Creating Apple test specifications..."
        public static let phase5Header = "\n⚙️ Phase 5: Defining technical requirements..."
        public static let phase6Header = "\n🚀 Phase 6: Apple deployment configuration..."
    }

    // MARK: - Default Values

    public enum DefaultValues {
        public static let testFramework = "XCTest"
        public static let language = "Swift"
        public static let coverageTarget = 80
        public static let iosMinimumVersion = "17.0"
        public static let macosMinimumVersion = "14.0"
        public static let swiftVersion = "5.9"
        public static let frameworks = ["SwiftUI", "Foundation", "Combine"]
        public static let platform = "Apple App Store"
        public static let defaultBaseURL = "https://api.example.com/v1"
        public static let unnamedProject = "Unnamed Project"
        public static let targetUsers = ["Developers", "Product Managers", "Business Analysts"]
        public static let architectureType = "Modular and Scalable"
        public static let prdThinkingMode = ThinkingModeManager.ThinkingMode.systemsThinking
    }

    // MARK: - Extraction Patterns

    public enum ExtractionPatterns {
        public static let userStoryPrefix = "As a"
        public static let acceptanceKeyword = "acceptance"
        public static let criteriaKeyword = "criteria"
        public static let httpsPrefix = "https://"
        public static let httpPrefix = "http://"
        public static let bearerAuth = "bearer"
        public static let apiKeyAuth = "api key"
        public static let oauth2Auth = "oauth"
    }

    // MARK: - Validation Keys

    public enum ValidationKeys {
        public static let hasOverview = "has_overview"
        public static let hasFeatures = "has_features"
        public static let hasAPISpecs = "has_api_specs"
        public static let hasTestSpecs = "has_test_specs"
        public static let hasDeployment = "has_deployment"
        public static let hasRequirements = "has_requirements"
        public static let hasTechnicalSpecs = "has_technical_specs"
        public static let featureCount = "feature_count"
        public static let readyForImplementation = "ready_for_implementation"
        public static let completenessCheck = "completeness_check"
        public static let validation = "validation"
    }

    // MARK: - Error Messages

    public enum ErrorMessages {
        public static let jsonGenerationError = "{ \"error\": \"Failed to generate JSON: %@\" }"
    }
}
