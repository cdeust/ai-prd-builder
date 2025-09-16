import Foundation
import AIBridge

/// Constants for PRD generation prompts and templates
public enum PRDConstants {

    // MARK: - ThinkingFramework Integration Constants

    public enum ThinkingIntegration {
        public static let problemTemplate = "Generate comprehensive product requirements for: %@"
        public static let contextTemplate = """
        Consider:
        - User needs and pain points
        - Technical feasibility
        - Market positioning
        - Success metrics
        - Potential risks
        """

        public static let constraints = [
            "Must be technically feasible",
            "Should solve real user problems",
            "Must be measurable",
            "Should align with Apple ecosystem best practices"
        ]

        // Assumptions
        public static let marketAssumption = "Target market exists and is accessible"
        public static let techAssumption = "Required technology is mature and stable"
        public static let featureFeasibilityTemplate = "Feature '%@' implementation is feasible"
        public static let featureValueTemplate = "Feature '%@' provides value to users"

        // Confidence levels
        public static let defaultBusinessConfidence: Float = 0.7
        public static let defaultTechnicalConfidence: Float = 0.8
        public static let baseFeatureConfidence: Float = 0.7
        public static let confidenceMultiplier: Float = 0.3

        // Decision tree
        public static let mvpPrioritizationQuestion = "Which features should be prioritized for MVP?"
        public static let productContextTemplate = "Product: %@\nFeatures: %@"
        public static let maxDecisionDepth = 3

        // Display
        public static let analyzingRequirements = "Analyzing requirements with reasoning..."
        public static let validationSummaryHeader = "Assumption Validation Summary:"

        // YAML section headers
        public static let reasoningHeader = "# PRD with Reasoning Insights\n\n"
        public static let reasoningAnalysis = "reasoning_analysis:\n"
        public static let conclusionKey = "  conclusion: |\n"
        public static let confidenceKey = "  confidence: %.2f\n"
        public static let assumptionsMadeKey = "  assumptions_made: %d\n\n"
        public static let assumptionsSection = "\nassumptions_and_risks:\n"
        public static let trackedAssumptionsKey = "  tracked_assumptions:\n"
        public static let contradictionsKey = "  potential_contradictions:\n"
        public static let totalAssumptionsKey = "  total_assumptions_tracked: %d\n"

        // Limits
        public static let maxAssumptionsToDisplay = 10
        public static let maxContradictionsToDisplay = 5
        public static let prdContentSummaryLength = 500

        // Validation responses
        public static let validationYes = "YES"
        public static let validationNo = "NO"
    }

    // MARK: - Phase 1 Prompts

    public enum Phase1 {
        public static let template = """
        Create a basic Product Requirements Document for: %@

        Focus on:
        1. Product vision (1-2 sentences)
        2. List of main features (provide 10-15 feature names, we'll detail them later)
        3. Target users (brief)
        4. High-level architecture type

        Important: Generate a comprehensive list of 10-15 distinct features that cover all aspects of the product.
        Keep descriptions concise - this is just the skeleton.
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
        Generate a complete, valid OpenAPI 3.1.0 specification for: %@

        CRITICAL: Generate ONE complete YAML document with ALL sections properly defined.

        Required structure (must be in exact order):

        openapi: "3.1.0"
        info:
          title: "[Main Entity/Service Name]"
          version: "1.0.0"
          description: "[Brief description]"
        servers:
          - url: "https://api.example.com/v1"
            description: "Production"
        paths:
          /[resources]:
            get:
              summary: "List all [resources]"
              operationId: "list[Resources]"
              parameters:
                - name: page
                  in: query
                  schema:
                    type: integer
                - name: limit
                  in: query
                  schema:
                    type: integer
              responses:
                '200':
                  $ref: '#/components/responses/[Resource]List'
            post:
              summary: "Create [resource]"
              operationId: "create[Resource]"
              requestBody:
                $ref: '#/components/requestBodies/[Resource]Input'
              responses:
                '201':
                  $ref: '#/components/responses/[Resource]Created'
                '400':
                  $ref: '#/components/responses/ErrorResponse'
          /[resources]/{id}:
            parameters:
              - name: id
                in: path
                required: true
                schema:
                  type: string
                  format: uuid
            get:
              summary: "Get [resource] by ID"
              operationId: "get[Resource]"
              responses:
                '200':
                  $ref: '#/components/responses/[Resource]Detail'
                '404':
                  $ref: '#/components/responses/ErrorResponse'
            put:
              summary: "Update [resource]"
              operationId: "update[Resource]"
              requestBody:
                $ref: '#/components/requestBodies/[Resource]Input'
              responses:
                '200':
                  $ref: '#/components/responses/[Resource]Updated'
                '400':
                  $ref: '#/components/responses/ErrorResponse'
                '404':
                  $ref: '#/components/responses/ErrorResponse'
            delete:
              summary: "Delete [resource]"
              operationId: "delete[Resource]"
              responses:
                '204':
                  description: "Successfully deleted"
                '404':
                  $ref: '#/components/responses/ErrorResponse'
          /health:
            get:
              summary: "Health check"
              operationId: "healthCheck"
              responses:
                '200':
                  description: "Service healthy"
                  content:
                    application/json:
                      schema:
                        type: object
                        properties:
                          status:
                            type: string
                            enum: [healthy]
                          timestamp:
                            type: string
                            format: date-time
        components:
          schemas:
            [Resource]:
              type: object
              required: [id, name]
              properties:
                id:
                  type: string
                  format: uuid
                  example: "550e8400-e29b-41d4-a716-446655440000"
                name:
                  type: string
                  minLength: 1
                  maxLength: 255
                  example: "Example [Resource]"
                createdAt:
                  type: string
                  format: date-time
                  example: "2024-01-15T09:30:00Z"
                updatedAt:
                  type: string
                  format: date-time
                  example: "2024-01-15T10:45:00Z"
            [Resource]Input:
              type: object
              required: [name]
              properties:
                name:
                  type: string
                  minLength: 1
                  maxLength: 255
                  example: "New [Resource]"
            Error:
              type: object
              required: [code, message]
              properties:
                code:
                  type: integer
                  example: 400
                message:
                  type: string
                  example: "Invalid request"
                details:
                  type: string
                  example: "Field 'name' is required"
            PaginatedList:
              type: object
              properties:
                items:
                  type: array
                  items:
                    type: object
                total:
                  type: integer
                  example: 100
                page:
                  type: integer
                  example: 1
                limit:
                  type: integer
                  example: 20
          responses:
            [Resource]List:
              description: "List of [resources]"
              content:
                application/json:
                  schema:
                    allOf:
                      - $ref: '#/components/schemas/PaginatedList'
                      - type: object
                        properties:
                          items:
                            type: array
                            items:
                              $ref: '#/components/schemas/[Resource]'
            [Resource]Created:
              description: "[Resource] created successfully"
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/[Resource]'
            [Resource]Detail:
              description: "[Resource] details"
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/[Resource]'
            [Resource]Updated:
              description: "[Resource] updated successfully"
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/[Resource]'
            ErrorResponse:
              description: "Error response"
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
          requestBodies:
            [Resource]Input:
              description: "[Resource] input data"
              required: true
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/[Resource]Input'
          securitySchemes:
            BearerAuth:
              type: http
              scheme: bearer
              bearerFormat: JWT
            ApiKey:
              type: apiKey
              in: header
              name: X-API-Key
        security:
          - BearerAuth: []

        INSTRUCTIONS:
        1. Replace [resource]/[Resource]/[resources] with actual entities from the context
        2. Generate ONLY the YAML spec, no markdown fences or explanatory text
        3. Ensure all $refs point to actually defined components
        4. All responses must use content/application/json/schema structure
        5. Include appropriate error responses for each endpoint
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
           - Launch time: iOS cold start < 2.0s (p95), warm < 1.0s
           - Memory usage: idle 150-250MB, peak < 500MB (device dependent)
           - Battery impact: minimal background activity, respect Low Power Mode
           - Network: implement retry logic, handle offline mode
           - Response times: API calls < 1.5-2.0s (p95)
           - Error handling: graceful degradation, clear error states

        5. Apple Human Interface Guidelines compliance:
           - Design system requirements
           - Accessibility standards (VoiceOver, Dynamic Type)
           - Platform-specific UI conventions

        6. Security and privacy:
           - Privacy Manifest (PrivacyInfo.xcprivacy):
             * Required reasons API usage
             * Data collection disclosure
             * Third-party SDK declarations
           - Keychain Services:
             * Store API tokens and credentials
             * Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly
           - Biometric authentication (Face ID/Touch ID)
           - App Transport Security (ATS) compliance
           - On-device inference privacy:
             * No PII in prompts to external services
             * Redact sensitive data in logs
             * Local model processing when possible
           - Data Protection:
             * Enable file protection (.completeFileProtection)
             * Encrypt local databases
           - Security Rules:
             * No hardcoded secrets or API keys
             * No production data in test/debug builds
             * Certificate pinning for critical endpoints

        Be specific with platform SDK versions and realistic performance targets.
        """

        public static let sectionHeader = "## TECHNICAL REQUIREMENTS\n\n"
        public static let sectionFooter = "\n\n"
    }

    // MARK: - Phase 6 Apple Deployment

    public enum Phase6 {
        public static let template = """
        Create Apple deployment configuration:

        1. Xcode Cloud CI/CD:
           - Build workflows (PR validation, main branch, release)
           - Automated testing (unit, UI, performance)
           - Post-actions (notifications, TestFlight upload)

        2. Code Signing & Provisioning:
           - Development certificates for team
           - Distribution certificate for App Store
           - App ID configuration with capabilities
           - Provisioning profiles (dev, ad-hoc, App Store)

        3. TestFlight Configuration:
           - Internal testing groups (dev team, QA)
           - External beta groups (limited users)
           - Build metadata and release notes
           - Automatic distribution via Xcode Cloud

        4. App Store Connect Preparation:
           - App metadata (name, description, keywords)
           - Screenshots (all device sizes)
           - App preview videos
           - Privacy policy URL
           - Support URL

        5. Phased Release Strategy:
           - TestFlight beta (2-4 weeks)
           - Phased App Store release (7-day rollout)
           - Monitor crash reports and metrics
           - Gradual rollout percentage increase

        6. Environment Configuration:
           - Xcode configurations (Debug, Release)
           - Scheme-based build settings
           - Environment-specific plist files
           - API endpoint configuration

        Follow Apple's official deployment workflow.
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

    // MARK: - Feature Management Constants

    public enum FeatureManagement {
        public static let maxFeaturesForEnrichment = 15  // Allow more features for comprehensive PRDs
        public static let minimumConfidenceThreshold: Float = 0.7  // Minimum confidence for feature inclusion
        public static let priorityFormat = "    priority: %.2f\n"
        public static let confidenceFormat = "    confidence: %.2f\n"
        public static let filteredFeaturesMessage = "Filtered out %d low-confidence features (< 0.7)"
        public static let featureItemTemplate = """
              - name: %@
                priority: %.2f
                description: %@
                assumption_impact: %@
                reasoning: Based on decision tree analysis

            """
        public static let defaultFeatureDescription = "Feature extracted from requirements analysis"
        public static let decisionTreeReasoning = "Based on decision tree analysis"

        // List markers for feature extraction
        public static let listMarkers = ["- ", "• ", "* ", "○ ", "→ "]
        public static let featurePrefix = "Feature:"
        public static let numberPattern = "^\\d+[\\.\\)]\\s*"

        // Classification prompt for distinguishing features from personas
        public static let classificationPromptTemplate = """
        Review these items extracted from a PRD overview:
        %@

        Context: %@

        For each item, determine if it's a FEATURE (capability/functionality) or PERSONA (user/audience).

        FEATURES are: capabilities, functionalities, integrations, processes, outputs
        PERSONAS are: user types, audiences, teams, stakeholders, organizations

        List ONLY the features, one per line, in this format:
        FEATURE: [exact feature name]

        Do not include personas/audiences in your response.
        """
    }

    // MARK: - OpenAPI Validation Constants

    public enum OpenAPIValidation {
        public static let maxIterations = 10
        public static let minConfidence: Float = 0.85
        public static let maxIssuesToDisplay = 3

        // Messages
        public static let iterationMessage = "OpenAPI Generation - Iteration %d/%d"
        public static let validationPassMessage = "  Validation: ✅ (confidence: %.2f)"
        public static let validationFailMessage = "  Validation: ❌ (confidence: %.2f)"
        public static let issuesFoundMessage = "  Issues found: %d"
        public static let issueItemPrefix = "    - "

        // Validation prompt template
        public static let validationPromptTemplate = """
        Validate this OpenAPI specification for correctness:

        %@

        Check ALL of these rules:

        1. NO DUPLICATES:
           - Each path (e.g., /resource) appears ONCE in paths section
           - All methods for a path (GET, POST, etc.) are grouped under that single path
           - Only ONE components section allowed
           - No duplicate schema names, response names, or security scheme names

        2. HTTP METHOD RULES:
           - GET: MUST NOT have requestBody (FORBIDDEN in OpenAPI)
           - POST/PUT/PATCH: MUST have requestBody with content and schema
           - DELETE: typically no requestBody
           - Path parameters in {brackets} MUST be declared in parameters

        3. RESPONSE STRUCTURE:
           - Responses with content MUST follow: responses → statusCode → content → media-type → schema
           - Array responses need: schema: { type: array, items: {$ref or type} }
           - NEVER put 'items' directly under responses

        4. SCHEMA PROPERTIES:
           - properties MUST be a map: propertyName: {type: string/number/etc}
           - NEVER use array syntax for properties
           - Use 'enum' for allowed values, NOT 'possibleValues' or other names
           - Date fields: use format: date-time (with time) or format: date (date only)

        5. SECURITY:
           - securitySchemes MUST be under components.securitySchemes
           - Bearer auth: type: http, scheme: bearer (lowercase)
           - API key: type: apiKey, in: header/query/cookie, name: X-API-Key
           - Root security: array of objects like [{BearerAuth: []}]
           - NEVER use invalid structures like bearerAuth: {jwt: {scopes:}}

        6. PARAMETERS:
           - Path params for /resource/{id} MUST declare 'id' in parameters
           - Parameter schema goes inside 'schema' property
           - Required path params: required: true

        7. FORBIDDEN:
           - No "..." or placeholder content
           - No custom keywords unless prefixed with x-
           - No invented field names

        Respond with:
        VALID: [YES/NO]
        CONFIDENCE: [0.0-1.0]
        ISSUES: [list each specific problem found, or "none"]

        Be EXTREMELY strict. Mark INVALID for ANY violation.
        """

        // Correction prompt template
        public static let correctionPromptTemplate = """
        Correct these issues in the OpenAPI specification:

        Issues to fix:
        %@

        Current spec:
        %@

        Generate the CORRECTED spec maintaining all functionality but fixing the issues.
        Ensure the output is valid OpenAPI 3.1.0 YAML.
        """

        // Force correction prompt template
        public static let forceCorrectionPromptTemplate = """
        CRITICAL: Fix these OpenAPI specification issues immediately:

        Issues found:
        %@

        Current spec:
        %@

        Generate a CORRECTED version that:
        1. Fixes ALL listed issues
        2. Maintains the original API intent
        3. Follows OpenAPI 3.1.0 rules EXACTLY:
           - openapi: "3.1.0"
           - info: (title, version, description)
           - servers: array with url
           - paths: endpoints with operations
           - components: schemas, securitySchemes, responses
           - security: array of security requirements

        CRITICAL FIXES REQUIRED:
        1. MERGE DUPLICATES:
           - If path appears twice, merge all methods under ONE path
           - If components appears twice, merge into ONE section

        2. FIX RESPONSES:
           - Array responses: responses → '200' → content → application/json → schema → {type: array, items: ...}
           - NEVER put 'items' directly under response

        3. FIX PROPERTIES:
           - Change array syntax to map: properties: {fieldName: {type: ...}}
           - Change 'possibleValues' to 'enum'

        4. FIX SECURITY:
           - Move securitySchemes to components.securitySchemes
           - Bearer: {type: http, scheme: bearer}
           - Root security: [{BearerAuth: []}] format

        5. FIX METHODS:
           - Remove requestBody from ALL GET operations
           - Add requestBody to POST/PUT/PATCH if missing
           - Add missing path parameters

        Return ONLY the corrected YAML, no explanation.
        """

        // Parsing patterns
        public static let validYesPattern = "VALID: YES"
        public static let validNoPattern = "VALID: NO"
        public static let confidencePattern = "CONFIDENCE:"
        public static let issuesPattern = "ISSUES:"
        public static let noneKeyword = "none"
        public static let listItemPrefixes = ["-", "*"]
    }

    // MARK: - Reasoning Engine Constants

    public enum ReasoningEngine {
        public static let minConfidence: Float = 0.75
        public static let maxIterations = 10

        // Messages
        public static let iterationMessage = "🧠 Reasoning iteration %d/%d"
        public static let confidenceMessage = "  Confidence: %.2f"
        public static let sufficientConfidenceMessage = "  ✅ Sufficient confidence achieved"
        public static let lowConfidenceMessage = "  ⚠️ Low confidence, refining analysis..."
        public static let refinementPrompt = "Previous analysis confidence was %.2f. Reconsidering with focus on missing evidence and alternative approaches."
        public static let reasoningFailedError = "Unable to generate confident analysis after %d attempts"
    }

    // MARK: - Error Messages

    public enum ErrorMessages {
        public static let reasoningFailedPrefix = "Reasoning failed: "
        public static let openAPIValidationFailedPrefix = "OpenAPI validation failed: "
        public static let featureExtractionFailedPrefix = "Feature extraction failed: "
        public static let assumptionValidationFailedPrefix = "Assumption validation failed: "
        public static let insufficientConfidencePrefix = "Insufficient confidence: "
        public static let jsonGenerationError = "{ \"error\": \"Failed to generate JSON: %@\" }"
    }

    // MARK: - YAML Builder Constants

    public enum YAMLBuilder {
        // Headers and sections
        public static let prdHeader = "# PRD Generated with AI Assistance\n\n"
        public static let metadataSection = "metadata:\n"
        public static let designRationaleSection = "\ndesign_rationale:\n"
        public static let evidenceSection = "  evidence:\n"
        public static let decisionsSection = "  decisions:\n"

        // Metadata fields
        public static let modelProviderKey = "  modelProvider: "
        public static let modelVersionKey = "  modelVersion: "
        public static let promptVersionKey = "  promptVersion: "
        public static let generatedAtKey = "  generatedAt: "
        public static let approvedByKey = "  approvedBy: "
        public static let baLintKey = "  ba_lint:\n"
        public static let baLintPassKey = "    pass: "
        public static let baLintIssuesKey = "    issues: "

        // Default values
        public static let defaultModelProvider = "Apple Intelligence (MLX)"
        public static let defaultModelVersion = "1.0.0"
        public static let defaultPromptVersion = "2.0.0"
        public static let defaultApprovedBy = "pending"
        public static let defaultBaLintPass = "false"
        public static let defaultBaLintIssues = "[]"

        // Evidence and decisions
        public static let evidenceItemPrefix = "    - "
        public static let primaryDecision = "    - Primary approach selected based on confidence level\n"
        public static let confidenceScoreFormat = "  confidence_score: %.2f\n"
        public static let validationRequiredFormat = "  validation_required: %d assumptions tracked\n\n"
        public static let maxEvidencePoints = 15

        // Formatting
        public static let newline = "\n"
        public static let doubleNewline = "\n\n"
    }

    // MARK: - YAML Formatting Constants

    public enum YAMLFormatting {
        // Assumption formatting
        public static let assumptionItemTemplate = """
            - statement: %@
              category: %@
              confidence: %.2f
              status: %@

        """

        // Contradiction formatting
        public static let contradictionItemTemplate = """
                - conflict: %@
                  resolution: %@

            """

        // Risk assessment formatting
        public static let identifiedRisksHeader = "Identified Risks:\n"
        public static let criticalAssumptionsHeader = "\nCritical Assumptions:\n"
        public static let riskItemFormat = "%d. %@\n"
        public static let assumptionRiskFormat = "- %@ (Impact: Critical)\n"

        // Alternative approaches formatting
        public static let alternativesHeader = "\nAlternative Approaches Considered:\n"
        public static let alternativeItemFormat = "\n%d. %@\n"
        public static let probabilityFormat = "   Probability of Success: %.2f\n"
        public static let prosFormat = "   Pros: %@\n"
        public static let consFormat = "   Cons: %@\n"

        // Validation formatting
        public static let validationFormat = """
        Validate if this PRD content aligns with the initial reasoning:

        Initial Conclusion:
        %@

        PRD Content Summary:
        %@...

        Does the PRD properly reflect the reasoning? (YES/NO)
        Explain any discrepancies.
        """

        // Reasoning prompt formatting
        public static let enhancedOverviewPrompt = """
        Based on the following analysis, generate a comprehensive product overview for: %@

        Key Insights from Analysis:
        %@

        Confidence Level: %.2f

        Include:
        - Product vision and strategic goals
        - Target users and their specific needs
        - Key differentiators in the market
        - Measurable success metrics
        - Core features (list format)
        """
    }

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

        // Thinking modes for different phases
        public static let phase1ThinkingMode = ThinkingModeManager.ThinkingMode.systemsThinking
        public static let phase2ThinkingMode = ThinkingModeManager.ThinkingMode.convergentThinking
        public static let phase3ThinkingMode = ThinkingModeManager.ThinkingMode.systemsThinking
        public static let phase4ThinkingMode = ThinkingModeManager.ThinkingMode.criticalAnalysis
        public static let phase5ThinkingMode = ThinkingModeManager.ThinkingMode.systemsThinking
        public static let phase6ThinkingMode = ThinkingModeManager.ThinkingMode.convergentThinking
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
}
