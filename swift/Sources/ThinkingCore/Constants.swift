import Foundation

// MARK: - AssumptionTracker Constants

public enum AssumptionTrackerConstants {
    public static let defaultConfidence: Float = 0.5
    static let partialValidationThreshold: Float = 0.3
    static let verifiedConfidenceThreshold: Float = 1.0
    static let validPercentageMultiplier: Float = 100.0

    // Log message templates
    static let validatingAllMessage = "Validating all unverified assumptions..."
    static let assumptionRecordedMessage = "Assumption recorded:"
    static let categoryConfidenceFormat = "   Category: %@, Confidence: %.2f"
    static let validatingAssumptionMessage = "Validating assumption:"
    static let validationResultFormat = "   Result: %@ %@ (confidence: %.2f)"
    static let checkingContradictionsMessage = "Checking for contradicting assumptions..."
    static let validLabel = "Valid"
    static let invalidLabel = "Invalid"

    // Prompt Templates
    static let extractAssumptionsPromptTemplate = """
        Extract all assumptions from this reasoning:
        %@

        For each assumption identify:
        ASSUMPTION: [the assumption being made]
        CATEGORY: [TECHNICAL/BUSINESS/USER/PERFORMANCE/SECURITY/DATA]
        CONFIDENCE: [0.0-1.0]
        DEPENDS_ON: [other assumptions it depends on, if any]
        IF_WRONG: [what happens if this is incorrect]
        """

    static let validateAssumptionPromptTemplate = """
        Validate this assumption:
        Assumption: %@
        Context: %@
        Category: %@
        %@

        Determine:
        1. Is this assumption valid? (YES/NO/PARTIAL)
        2. What evidence supports or contradicts it?
        3. What's the confidence level? (0.0-1.0)
        4. What are the implications if wrong?

        Format:
        VALID: [YES/NO/PARTIAL]
        EVIDENCE: [supporting or contradicting evidence]
        CONFIDENCE: [0.0-1.0]
        IMPLICATIONS: [what happens if wrong]
        """

    static let assessImpactPromptTemplate = """
        Assess the impact if this assumption is wrong:
        Assumption: %@
        Context: %@
        Category: %@

        Determine:
        1. SCOPE: [LOCAL/MODULE/SYSTEM/CRITICAL]
        2. SEVERITY: [LOW/MEDIUM/HIGH/CRITICAL]
        3. AFFECTED: [list of affected components]
        4. MITIGATION: [how to handle if wrong]
        """

    static let findContradictionsPromptTemplate = """
        Find any contradictions in these assumptions:
        %@

        For each contradiction:
        ASSUMPTION1: [ID of first assumption]
        ASSUMPTION2: [ID of second assumption]
        CONFLICT: [why they contradict]
        RESOLUTION: [how to resolve]
        """
}

// MARK: - ChainOfThought Constants

public enum ChainOfThoughtConstants {
    static let defaultConfidence: Float = 0.5
    static let defaultThinkingModeName = "chain-of-thought"  // String representation for ThinkingMode
    static let minimumConfidence: Float = 0.1
    static let lowConfidenceThreshold: Float = 0.4
    static let observationConfidence: Float = 0.9
    static let reasoningConfidence: Float = 0.8
    static let warningConfidence: Float = 0.7
    static let conclusionConfidence: Float = 0.85
    static let overconfidenceThreshold: Float = 0.95
    static let assumptionOverloadThreshold: Int = 5
    static let patternThreshold: Int = 2
    static let antiPatternThreshold: Int = 5
    static let maxExamples: Int = 3
    static let maxPatternDisplay: Int = 5

    // Pattern names
    static let repeatedAssumptionPattern = "Repeated Assumption"
    static let lowConfidencePattern = "Low Confidence Pattern"

    // Recommendations
    static let assumptionRecommendation = "Validate this assumption explicitly before proceeding"
    static let confidenceRecommendation = "Increase confidence by gathering more information or adding validation"

    // Display formats
    static let summaryHeader = "\n=== Chain of Thought Summary ===\n"
    static let thoughtHistoryFormat = "Thought Chains: %d\n"
    static let assumptionCountFormat = "Total Assumptions: %d\n"
    static let patternsDetectedHeader = "\nDetected Patterns:\n"
    static let avgConfidenceFormat = "Average Confidence: %.2f\n"

    // Thought type prompts
    static let thoughtTypePrefix = "You are analyzing step-by-step.\n"
    static let observationPrompt = "Observe and describe what you see:\n"
    static let assumptionPrompt = "Identify assumptions being made:\n"
    static let reasoningPrompt = "Apply logical reasoning:\n"
    static let questionPrompt = "What questions need to be answered:\n"
    static let conclusionPrompt = "Draw a conclusion based on the analysis:\n"
    static let warningPrompt = "Identify potential issues or risks:\n"
    static let alternativePrompt = "Consider alternative approaches:\n"

    // Extraction template
    static let extractAssumptionsTemplate = """
        Extract assumptions from this text:
        %@

        Format each assumption as:
        ASSUMPTION: [statement]
        CONFIDENCE: [0.0-1.0]
        IMPACT: [CRITICAL/HIGH/MEDIUM/LOW]
        """

    // Process messages
    static let reasoningProcessStart = "\n🧠 Chain of Thought: Starting reasoning process"
    static let problemPrefix = "Problem: "
    static let reasoningComplete = "✅ Chain of Thought: Reasoning complete"
    static let conclusionPrefix = "   Conclusion: "
    static let confidencePrefix = "   Confidence: "

    // Thought prompts
    static let observePromptFormat = "Observe: %@"
    static let questionsPromptFormat = "What questions should I ask about: %@"
    static let assumptionsPromptFormat = "What assumptions am I making about: %@"
    static let reasonPromptFormat = "Reason through: %@\nConstraints: %@"
    static let alternativesPromptFormat = "What are alternative approaches to: %@"
    static let warningsPromptFormat = "What could go wrong with solving: %@"
    static let concludePromptFormat = "Based on the reasoning, conclude about: %@"

    // Error messages
    static let errorGeneratingThoughtFormat = "Error generating thought: %@"

    // Analysis formatting
    static let analysisHeader = "=== Thought Chain Analysis ===\n"
    static let analysisProblemFormat = "Problem: %@\n"
    static let analysisConclusionFormat = "Conclusion: %@\n"
    static let analysisConfidenceFormat = "Confidence: %.2f\n"
    static let analysisThoughtCountFormat = "Number of thoughts: %d\n"
    static let analysisAssumptionsHeader = "\nAssumptions:\n"
    static let analysisAssumptionFormat = "  - %@ (confidence: %.2f)\n"

    // Prompt Templates
    static let breakdownProblemPromptTemplate = """
        Break down this problem into its core components:
        Problem: %@
        %@

        Identify:
        1. What we're trying to achieve
        2. What we know
        3. What we don't know
        4. Key challenges

        Be specific and analytical.
        """

    static let identifyAssumptionsPromptTemplate = """
        Based on this problem and breakdown:
        Problem: %@
        Breakdown: %@

        List all assumptions we're making. For each:
        ASSUMPTION: [what we're assuming]
        CONFIDENCE: [0.0-1.0]
        IMPACT: [CRITICAL/HIGH/MEDIUM/LOW]
        IF_WRONG: [what happens if this assumption is incorrect]
        """

    static let generateReasoningStepsPromptTemplate = """
        Generate step-by-step reasoning for solving:
        Problem: %@

        Given assumptions:
        %@

        Constraints:
        %@

        Provide logical steps that:
        1. Build on each other
        2. Check assumptions when possible
        3. Stay within constraints
        4. Lead to a solution

        Format: One step per line, numbered.
        """

    static let identifyPotentialIssuesPromptTemplate = """
        Review this reasoning chain for potential issues:
        Problem: %@
        Reasoning steps:
        %@

        Identify:
        1. Logic flaws
        2. Missing edge cases
        3. Incorrect assumptions
        4. Anti-patterns
        5. Performance concerns

        List each issue clearly.
        """

    static let generateAlternativesPromptTemplate = """
        Given this solution approach:
        Problem: %@
        Main approach:
        %@

        Generate 2-3 alternative approaches.

        For each alternative provide:
        APPROACH: [description]
        PROBABILITY: [0.0-1.0 success likelihood]
        PROS: [advantages]
        CONS: [disadvantages]
        """

    static let formConclusionPromptTemplate = """
        Form a conclusion based on this reasoning:
        Problem: %@

        Recent thoughts:
        %@

        Alternatives considered: %d

        Provide a clear, actionable conclusion that:
        1. Addresses the original problem
        2. Acknowledges key assumptions
        3. Suggests next steps
        4. Notes any risks

        Keep it concise but complete.
        """
}

// MARK: - DecisionTree Constants

public enum DecisionTreeConstants {
    static let defaultMaxDepth: Int = 5
    static let defaultProbability: Float = 0.5
    static let minOptions: Int = 2
    static let maxOptions: Int = 4
    static let expansionProbabilityThreshold: Float = 0.3
    static let complexityThreshold: Int = 2
    static let minExpansionDepth: Int = 2
    static let riskPenaltyMultiplier: Float = 0.1

    // String constants
    static let emptyString = ""
    static let listSeparator = ", "
    static let contextSeparator = " -> "
    static let treeIndent = "    "
    static let nodeEmoji = "📍"
    static let selectedEmoji = "✓"
    static let branchSymbol = "├──"
    static let leafSymbol = "└──"
    static let probabilityFormat = " (p=%.2f)"

    // Navigation messages
    static let buildingTreeMessage = "\n🌳 Building Decision Tree"
    static let problemPrefixMessage = "Problem: "
    static let navigationStart = "\n🧭 Navigating Decision Tree"
    static let navigationComplete = "Navigation complete"
    static let selectOptionPrompt = "Select an option (enter number): "

    // Display formats
    static let currentNodeFormat = "\nCurrent Decision: %@"
    static let optionDisplayFormat = "  %d. %@ (probability: %.2f)"
    static let selectedFormat = "  ✓ Selected: %@"
    static let summaryHeader = "\n=== Decision Path Summary ===\n"
    static let stepFormat = "Step %d: %@\n"
    static let decisionFormat = "  Decision: %@\n"
    static let optionDescriptionFormat = """
        Option %d: %@
        Pros: %@
        Cons: %@
        Probability: %.2f
        Risk: %@

        """

    // Risk Values
    static let lowRiskValue: Int = 1
    static let mediumRiskValue: Int = 2
    static let highRiskValue: Int = 3
    static let criticalRiskValue: Int = 4
    static let maxRiskValue: Float = 4.0
    static let unknownRisk = "Unknown Risk"

    // Risk level descriptions
    static let lowRiskDescription = "Low Risk"
    static let mediumRiskDescription = "Medium Risk"
    static let highRiskDescription = "High Risk"
    static let criticalRiskDescription = "Critical Risk"

    // Risk Descriptions - Note: This will need to be computed at runtime
    // since we can't reference DecisionNode.Option.RiskLevel in a static context

    // Additional prompt templates
    static let rootQuestionPromptTemplate = """
        Given this problem: %@

        What is the primary decision that needs to be made?
        Formulate it as a clear, actionable question.
        """

    static let contextAdditionTemplate = "\nContext: %@"

    static let childQuestionPromptTemplate = """
        Previous decision: %@
        Selected option: %@
        Pros: %@
        Cons: %@

        What follow-up decision needs to be made based on this choice?
        Formulate as a clear question.
        """

    static let recommendationPromptTemplate = """
        Evaluate these options and recommend the best one:
        %@

        Consider probability of success, risk level, and overall benefits.
        Reply with just the option number (1, 2, 3, etc.)
        """

    // Prompt Templates
    static let generateRootQuestionPromptTemplate = """
        Create the first decision question for this problem:
        Problem: %@
        %@

        The question should:
        1. Address the most fundamental choice
        2. Be clear and binary/multiple choice
        3. Lead to meaningful different paths

        Return just the question.
        """

    static let generateOptionsPromptTemplate = """
        Generate 2-4 options for this decision:
        Question: %@
        Context: %@

        For each option provide:
        OPTION: [description]
        PROS: [comma-separated benefits]
        CONS: [comma-separated drawbacks]
        PROBABILITY: [0.0-1.0 success chance]
        RISK: [LOW/MEDIUM/HIGH/CRITICAL]

        Make options distinct and meaningful.
        """

    static let generateFollowUpQuestionPromptTemplate = """
        Given this decision path:
        Previous question: %@
        Selected: %@
        Context: %@

        What's the next decision that needs to be made?

        Return a follow-up question, or empty string if this is a final decision.
        """

    static let getAIRecommendationPromptTemplate = """
        Given this decision:
        Question: %@
        Context: %@

        Options:
        %@

        Which option would you recommend and why?
        Return just the option description.
        """

    static let explainChoicePromptTemplate = """
        Explain this decision:
        Question: %@
        Chosen: %@
        Strategy: %@

        Why this choice makes sense given:
        - Probability: %.2f
        - Risk: %@
        - Pros: %@
        - Cons: %@

        Be concise but clear.
        """
}

// MARK: - UI/Display Constants

public enum ThinkingFrameworkDisplay {
    // Emoji indicators
    static let assumptionEmoji = "💭"
    public static let validationEmoji = "🔍"
    static let validEmoji = "✅"
    static let invalidEmoji = "❌"
    static let warningEmoji = "⚠️"
    public static let brainEmoji = "🧠"
    static let treeEmoji = "🌳"
    static let nodeEmoji = "📍"
    static let navigationEmoji = "🧭"
    static let checkmarkEmoji = "✓"
    static let circleEmoji = "○"
    static let breakdownEmoji = "📊"
    static let linkEmoji = "🔗"
    static let searchEmoji = "🔎"

    // Tree visualization
    static let treeIndent = "    "
    static let treeBranch = "  "

    // Navigation Strategy descriptions
    static let highestProbabilityDesc = "Highest Probability"
    static let lowestRiskDesc = "Lowest Risk"
    static let balancedDesc = "Balanced"
    static let aiRecommendedDesc = "AI Recommended"
    static let interactiveDesc = "Interactive"

    // Decision Error descriptions
    static let noOptionsError = "No options available for the current decision node"
    static let invalidNodeError = "Invalid decision node encountered"
    static let maxDepthReachedError = "Maximum depth reached in decision tree"
    static let invalidSelectionError = "Invalid option selection"
}

// MARK: - Parser Constants

public enum ParserConstants {
    // Field prefixes
    static let assumptionPrefix = "ASSUMPTION:"
    static let categoryPrefix = "CATEGORY:"
    static let confidencePrefix = "CONFIDENCE:"
    static let dependsOnPrefix = "DEPENDS_ON:"
    static let validPrefix = "VALID:"
    static let evidencePrefix = "EVIDENCE:"
    static let implicationsPrefix = "IMPLICATIONS:"
    static let scopePrefix = "SCOPE:"
    static let severityPrefix = "SEVERITY:"
    static let affectedPrefix = "AFFECTED:"
    static let mitigationPrefix = "MITIGATION:"
    static let optionPrefix = "OPTION:"
    static let prosPrefix = "PROS:"
    static let consPrefix = "CONS:"
    static let probabilityPrefix = "PROBABILITY:"
    static let riskPrefix = "RISK:"
    static let approachPrefix = "APPROACH:"
    static let impactPrefix = "IMPACT:"
    static let ifWrongPrefix = "IF_WRONG:"

    // Keywords for parsing
    static let yesKeyword = "YES"
    static let partialKeyword = "PARTIAL"
    static let criticalKeyword = "CRITICAL"
    static let highKeyword = "HIGH"
    static let mediumKeyword = "MEDIUM"
    static let lowKeyword = "LOW"
    static let systemKeyword = "SYSTEM"
    static let moduleKeyword = "MODULE"
    static let localKeyword = "LOCAL"
    static let finalKeyword = "final"
    static let noneKeyword = "none"

    // Category keywords
    static let businessCategory = "BUSINESS"
    static let userCategory = "USER"
    static let performanceCategory = "PERFORMANCE"
    static let securityCategory = "SECURITY"
    static let dataCategory = "DATA"
    static let technicalCategory = "TECHNICAL"
}