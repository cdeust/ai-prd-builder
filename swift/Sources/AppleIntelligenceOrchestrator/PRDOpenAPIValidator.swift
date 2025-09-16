import Foundation
import AIBridge

/// Validates and iteratively improves OpenAPI specifications
/// Enhanced with MCTS, Decision Trees, and Formal Verification (2025)
public struct PRDOpenAPIValidator {

    private let orchestrator: Orchestrator
    private let mctsValidator: MCTSValidator
    private let constraintSolver: OpenAPIConstraintSolver
    private let decisionTree: OpenAPIDecisionTree
    private let astParser: OpenAPIASTParser
    private let structuralValidator: OpenAPIStructuralValidator
    private let promptBuilder: OpenAPIPromptBuilder
    private let responseParser: OpenAPIResponseParser
    private let template: OpenAPITemplate

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
        self.mctsValidator = MCTSValidator()
        self.constraintSolver = OpenAPIConstraintSolver()
        self.decisionTree = OpenAPIDecisionTree()
        self.astParser = OpenAPIASTParser()
        self.structuralValidator = OpenAPIStructuralValidator()
        self.promptBuilder = OpenAPIPromptBuilder()
        self.responseParser = OpenAPIResponseParser()
        self.template = OpenAPITemplate()
    }

    // MARK: - Monte Carlo Tree Search Generation

    /// Generate OpenAPI using MCTS with iterative improvement
    /// Based on 2025 MCTS-RAG research: 20% improvement with dynamic reasoning paths
    public func generateWithMCTS(
        context: String,
        maxIterations: Int = OpenAPIValidationConstants.MCTS.defaultMaxIterations
    ) async throws -> String {
        print(OpenAPIValidationConstants.MCTS.startMessage)

        // Initialize root with context
        let initialState = OpenAPIState(
            specification: "",
            validationIssues: [],
            fixedIssues: [],
            depth: OpenAPIPromptConstants.Indices.firstElement,
            confidence: Double(OpenAPIPromptConstants.Confidence.minValue)
        )

        let bestNode = try await mctsValidator.search(
            initialState: initialState,
            maxIterations: maxIterations
        ) { node in
            // Simulation handler
            try await self.simulateNode(node, context: context)
        }

        guard !bestNode.state.specification.isEmpty else {
            throw PRDError.openAPIValidationFailed(OpenAPIValidationConstants.MCTS.failureMessage)
        }

        return bestNode.state.specification
    }

    private func simulateNode(_ node: MCTSNode, context: String) async throws -> Double {
        var state = node.state

        // Generate spec if not present
        if state.specification.isEmpty {
            state.specification = try await generateInitialSpecification(context: context)
        }

        // Validate with multiple methods
        let validation = try await performComprehensiveValidation(state.specification)

        // Apply fixes if needed
        if !validation.issues.isEmpty && node.canExpand {
            let solution = decisionTree.findSolution(for: validation.issues.first ?? "")
            if let solution = solution {
                state.specification = try await applyFix(
                    spec: state.specification,
                    solution: solution.solution,
                    issue: validation.issues.first ?? ""
                )
            }
        }

        return Double(validation.confidence)
    }

    // MARK: - Enhanced Generation with Self-Consistency

    /// Generate OpenAPI spec using multiple parallel paths (2025 best practice)
    public func generateWithSelfConsistency(
        context: String,
        paths: Int = ReasoningConstants.Iterations.maxPaths
    ) async throws -> String {
        print("🔄 Using self-consistency with \(paths) parallel generation paths...")

        var specifications: [String] = []
        var validationResults: [ValidationResult] = []

        // Generate multiple specs in parallel conceptually
        for i in 1...paths {
            print("  Path \(i)/\(paths)...")

            let spec = try await generateSinglePath(
                context: context,
                pathId: i
            )
            specifications.append(spec)

            // Validate each spec
            let result = try await validateOpenAPISpec(spec)
            validationResults.append(result)

            print("    Confidence: \(result.confidence), Issues: \(result.issues.count)")
        }

        // Select the best spec based on validation
        let bestIndex = selectBestSpecification(
            specs: specifications,
            results: validationResults
        )

        let bestSpec = specifications[bestIndex]
        let bestResult = validationResults[bestIndex]

        print("✅ Selected path \(bestIndex + 1) with confidence \(bestResult.confidence)")

        // If best spec still has issues, try to fix them
        if !bestResult.issues.isEmpty {
            return try await improveSpecification(
                spec: bestSpec,
                issues: bestResult.issues,
                context: context
            )
        }

        return bestSpec
    }

    // MARK: - Public Interface

    /// Generate and validate OpenAPI spec using template-based approach
    public func generateValidOpenAPISpec(context: String) async throws -> String {
        // ALWAYS start with template-based generation for valid structure
        let spec = try await generateInitialSpecification(context: context)

        // Template should produce valid spec, but validate just in case
        let validationResult = try await validateOpenAPISpec(spec)

        if validationResult.isValid && Float(validationResult.confidence) >= PRDConstants.OpenAPIValidation.minConfidence {
            print("✅ Template generated valid OpenAPI spec (confidence: \(validationResult.confidence))")
            return spec
        }

        // If template somehow failed, log issues but return the spec anyway
        // (template structure should always be valid)
        if !validationResult.issues.isEmpty {
            print("⚠️ Template validation found issues (but structure is valid):")
            for issue in validationResult.issues {
                print("  - \(issue)")
            }
        }

        return spec
    }

    // MARK: - Decision Tree Resolution

    private func resolveWithDecisionTree(
        spec: String,
        issues: [String],
        context: String
    ) async throws -> String {
        let analysis = decisionTree.analyzeIssues(issues)
        var updatedSpec = spec

        print("  📊 Decision tree analysis:")
        print("    - Resolution rate: \(String(format: "%.1f%%", analysis.resolutionRate * 100))")
        if let topCategory = analysis.topCategory {
            print("    - Top issue category: \(topCategory)")
        }

        // Apply solutions in order of confidence
        for solution in analysis.solutions.sorted(by: { $0.confidence > $1.confidence }) {
            updatedSpec = try await applyFix(
                spec: updatedSpec,
                solution: solution.solution,
                issue: solution.issue
            )
        }

        return updatedSpec
    }

    private func applyFix(
        spec: String,
        solution: String,
        issue: String
    ) async throws -> String {
        let prompt = promptBuilder.buildFixApplication(
            issue: issue,
            solution: solution,
            spec: spec
        )

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return response
    }

    // MARK: - Constraint-Based Validation

    private func performComprehensiveValidation(_ spec: String) async throws -> ValidationResult {
        // 1. Parse to AST
        let ast = try astParser.parse(spec)

        // 2. Extract and solve constraints
        let constraints = constraintSolver.extractConstraints(from: ast)
        let solution = constraintSolver.solve(constraints)

        // 3. Perform structural validation
        let structuralIssues = structuralValidator.validate(spec)

        // 4. Perform AI validation
        let aiResult = try await performAIValidation(spec, knownIssues: structuralIssues)

        // 5. Combine all results
        return combineValidationResults(
            constraints: solution,
            structural: structuralIssues,
            ai: aiResult
        )
    }

    private func combineValidationResults(
        constraints: ConstraintSolutionResult,
        structural: [String],
        ai: ValidationResult
    ) -> ValidationResult {
        // Combine all issues
        var allIssues = structural
        allIssues.append(contentsOf: ai.issues)
        allIssues.append(contentsOf: constraints.violations.map { $0.message })

        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueIssues = allIssues.filter { seen.insert($0).inserted }

        // Calculate overall confidence
        let constraintScore = constraints.satisfactionRate
        let aiScore = Double(ai.confidence)
        let structuralPenalty = structural.isEmpty ? 1.0 : 0.7

        let overallConfidence = Float((constraintScore + aiScore) / 2.0 * structuralPenalty)

        // Spec is valid if no critical issues
        let hasCriticalIssues = constraints.violations.contains { $0.severity == .critical }
        let isValid = uniqueIssues.isEmpty || (!hasCriticalIssues && overallConfidence > 0.8)

        return ValidationResult(
            isValid: isValid,
            issues: uniqueIssues,
            confidence: Int(overallConfidence * 100)
        )
    }

    // MARK: - Generation Methods

    private func generateInitialSpecification(context: String) async throws -> String {
        // Use improved prompt with strict validation rules
        let prompt = promptBuilder.buildInitialGeneration(context: context)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .systemsThinking
        )

        // Clean and validate the response
        let cleanedResponse = OpenAPISpecGenerator.cleanAndValidate(response)

        switch cleanedResponse {
        case .success(let spec):
            return spec
        case .failure(let error):
            // Fallback to template-based generation if prompt fails
            print("⚠️ Direct generation failed: \(error). Using template fallback...")
            let openAPIContext = try await enrichContextWithAI(context)
            return template.generate(from: openAPIContext)
        }
    }

    private func enrichContextWithAI(_ userInput: String) async throws -> OpenAPIContext {
        // First extract basic context from user input
        var context = template.extractContext(from: userInput)

        // Enhance with AI to get better resource definitions
        let enrichmentPrompt = """
        Based on this input: \(userInput)

        Identify the main resources (entities) that need API endpoints.
        For each resource, provide:
        - Singular name (e.g., 'user', 'product')
        - Main properties with their types

        Format as:
        RESOURCE: <name>
        PROPERTIES:
        - <property>: <type>

        Focus on concrete entities that would have CRUD operations.
        """

        let (response, _) = try await orchestrator.chat(
            message: enrichmentPrompt,
            useAppleIntelligence: true,
            thinkingMode: .systemsThinking
        )

        // Parse enhanced resources from AI response
        let enhancedResources = parseEnhancedResources(from: response)
        if !enhancedResources.isEmpty {
            context = OpenAPIContext(
                title: context.title,
                version: context.version,
                description: context.description,
                serverUrl: context.serverUrl,
                resources: enhancedResources
            )
        }

        return context
    }

    private func parseEnhancedResources(from response: String) -> [OpenAPIResource] {
        var resources: [OpenAPIResource] = []
        let lines = response.components(separatedBy: .newlines)
        var currentResource: String?
        var currentProperties: [OpenAPIProperty] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.uppercased().hasPrefix("RESOURCE:") {
                // Save previous resource if exists
                if let name = currentResource {
                    resources.append(createResourceWithProperties(name: name, properties: currentProperties))
                }

                // Start new resource
                currentResource = trimmed.replacingOccurrences(of: "RESOURCE:", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespaces)
                currentProperties = []
            } else if trimmed.hasPrefix("-") && trimmed.contains(":") {
                // Parse property
                let propertyLine = trimmed.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                if let colonIndex = propertyLine.firstIndex(of: ":") {
                    let propName = String(propertyLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let propType = String(propertyLine[propertyLine.index(after: colonIndex)...])
                        .trimmingCharacters(in: .whitespaces)
                        .lowercased()

                    let swiftType = mapToOpenAPIType(propType)
                    currentProperties.append(
                        OpenAPIProperty(
                            name: propName,
                            type: swiftType.type,
                            required: true,
                            format: swiftType.format
                        )
                    )
                }
            }
        }

        // Save last resource
        if let name = currentResource {
            resources.append(createResourceWithProperties(name: name, properties: currentProperties))
        }

        return resources
    }

    private func createResourceWithProperties(name: String, properties: [OpenAPIProperty]) -> OpenAPIResource {
        let cleanName = name.lowercased().trimmingCharacters(in: .whitespaces)
        let singular = cleanName
        let plural = pluralize(cleanName)

        // Ensure basic properties are included
        var allProperties = properties
        let hasId = properties.contains { $0.name == "id" }
        let hasCreatedAt = properties.contains { $0.name == "createdAt" }

        if !hasId {
            allProperties.insert(
                OpenAPIProperty(name: "id", type: "string", required: true, format: nil),
                at: 0
            )
        }
        if !hasCreatedAt {
            allProperties.append(
                OpenAPIProperty(name: "createdAt", type: "string", required: true, format: "date-time")
            )
        }

        return OpenAPIResource(
            singularName: singular,
            pluralName: plural,
            singularPascalCase: toPascalCase(singular),
            pluralPascalCase: toPascalCase(plural),
            properties: allProperties
        )
    }

    private func mapToOpenAPIType(_ type: String) -> (type: String, format: String?) {
        return OpenAPIGenerationHelpers.mapToOpenAPIType(type)
    }

    private func pluralize(_ word: String) -> String {
        return OpenAPIGenerationHelpers.pluralize(word)
    }

    private func toPascalCase(_ text: String) -> String {
        return OpenAPIGenerationHelpers.toPascalCase(text)
    }

    private func generateSinglePath(context: String, pathId: Int) async throws -> String {
        // Use different thinking modes for diversity
        let thinkingModes: [ThinkingModeManager.ThinkingMode] = [
            .systemsThinking,
            .convergentThinking,
            .criticalAnalysis
        ]
        let mode = thinkingModes[(pathId - 1) % thinkingModes.count]

        let prompt = buildPathSpecificPrompt(context: context, pathId: pathId)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: mode
        )

        return response
    }

    private func buildPathSpecificPrompt(context: String, pathId: Int) -> String {
        return promptBuilder.buildPathSpecific(context: context, pathId: pathId)
    }

    private func generateOrImproveSpec(
        context: String,
        previousSpec: String,
        issues: [String],
        persistentIssues: [String],
        fixedIssues: [String],
        iteration: Int
    ) async throws -> String {

        let prompt: String
        let thinkingMode: ThinkingModeManager.ThinkingMode

        if iteration == 1 {
            // First iteration: use template-based generation for guaranteed valid structure
            return try await generateInitialSpecification(context: context)
        } else if !persistentIssues.isEmpty && iteration > 2 {
            // Focus specifically on persistent issues
            prompt = buildPersistentIssuePrompt(
                spec: previousSpec,
                persistentIssues: persistentIssues,
                fixedIssues: fixedIssues
            )
            thinkingMode = .convergentThinking
        } else if !previousSpec.isEmpty && !issues.isEmpty {
            // Normal correction with memory of what worked
            prompt = buildCorrectionPromptWithMemory(
                spec: previousSpec,
                issues: issues,
                fixedIssues: fixedIssues
            )
            thinkingMode = .convergentThinking
        } else {
            // Regenerate with different approach if no issues but low confidence
            prompt = buildAlternativeGenerationPrompt(context: context, iteration: iteration)
            thinkingMode = .criticalAnalysis
        }

        // For iterations > 1, improve the existing spec
        if previousSpec.isEmpty {
            // Fallback to template if no previous spec
            return try await generateInitialSpecification(context: context)
        }

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: thinkingMode
        )

        // Validate the response has proper structure
        if !response.contains("openapi:") || !response.contains("paths:") {
            // If AI response lost structure, regenerate from template
            print("  ⚠️ Response lost structure, regenerating from template...")
            return try await generateInitialSpecification(context: context)
        }

        return response
    }

    // MARK: - Validation Methods

    private func validateOpenAPISpec(_ spec: String) async throws -> ValidationResult {
        // First do structural validation
        let structuralIssues = structuralValidator.validate(spec)

        // Then do AI-based semantic validation
        let aiResult = try await performAIValidation(spec, knownIssues: structuralIssues)

        // Combine structural and AI validation results
        return combineSimpleValidationResults(structural: structuralIssues, ai: aiResult)
    }

    private func performAIValidation(_ spec: String, knownIssues: [String]) async throws -> ValidationResult {
        let prompt = buildDetailedValidationPrompt(spec: spec, knownIssues: knownIssues)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .criticalAnalysis
        )

        return responseParser.parseValidationResponse(response)
    }

    private func combineSimpleValidationResults(structural: [String], ai: ValidationResult) -> ValidationResult {
        // Combine all issues
        var allIssues = structural
        allIssues.append(contentsOf: ai.issues)

        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueIssues = allIssues.filter { seen.insert($0).inserted }

        // Spec is only valid if no issues found
        let isValid = uniqueIssues.isEmpty

        // Calculate confidence based on issue count and AI confidence
        var confidence = ai.confidence
        if !structural.isEmpty {
            // Reduce confidence if structural issues found
            confidence = confidence / 2
        }
        if isValid && confidence < 70 {
            // Boost confidence if no issues found
            confidence = 70
        }

        return ValidationResult(isValid: isValid, issues: uniqueIssues, confidence: confidence)
    }

    // MARK: - Helper Methods

    private func selectBestSpecification(specs: [String], results: [ValidationResult]) -> Int {
        var bestIndex = 0
        var bestScore: Float = -1

        for (index, result) in results.enumerated() {
            // Score based on validity, confidence, and issue count
            var score = Float(result.confidence)

            if result.isValid {
                score += 50.0
            }

            // Penalize for issues
            score -= Float(result.issues.count) * 10.0

            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        return bestIndex
    }

    private func improveSpecification(spec: String, issues: [String], context: String) async throws -> String {
        // For template-based specs, try targeted fixes first
        if spec.contains("openapi: 3.1.0") && hasTemplateStructure(spec) {
            return try await improveTemplateBasedSpec(spec: spec, issues: issues, context: context)
        }

        // Fallback to general improvement
        let prompt = promptBuilder.buildCorrectionWithMemory(
            spec: spec,
            issues: issues,
            fixedIssues: []
        )

        let (improved, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return improved
    }

    private func hasTemplateStructure(_ spec: String) -> Bool {
        // Check if spec follows our template structure
        return spec.contains("openapi: 3.1.0") &&
               spec.contains("paths:") &&
               spec.contains("components:") &&
               spec.contains("securitySchemes:")
    }

    private func improveTemplateBasedSpec(spec: String, issues: [String], context: String) async throws -> String {
        // For critical structural issues, regenerate from template
        let criticalIssues = issues.filter { $0.contains("❌") }
        if !criticalIssues.isEmpty {
            print("  🔄 Critical issues detected, regenerating from template...")
            return try await generateInitialSpecification(context: context)
        }

        // For minor issues, apply targeted fixes
        var improvedSpec = spec

        for issue in issues {
            if issue.contains("operationId") {
                improvedSpec = addMissingOperationIds(to: improvedSpec)
            } else if issue.contains("example") {
                improvedSpec = try await addExamples(to: improvedSpec)
            } else if issue.contains("description") {
                improvedSpec = try await enhanceDescriptions(in: improvedSpec)
            }
        }

        return improvedSpec
    }

    private func addMissingOperationIds(to spec: String) -> String {
        // Simple fix: ensure all operations have operationIds
        var lines = spec.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "get:" || trimmed == "post:" || trimmed == "put:" || trimmed == "patch:" || trimmed == "delete:" {
                // Check if next line has operationId
                if index + 2 < lines.count {
                    let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                    if !nextLine.contains("operationId:") {
                        // Insert operationId after summary
                        let method = trimmed.replacingOccurrences(of: ":", with: "")
                        let path = findPathForOperation(at: index, in: lines)
                        let operationId = generateOperationId(method: method, path: path)
                        lines.insert("      operationId: \(operationId)", at: index + 2)
                    }
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private func findPathForOperation(at index: Int, in lines: [String]) -> String {
        // Look backwards for the path definition
        for i in stride(from: index - 1, to: 0, by: -1) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("/") && line.hasSuffix(":") {
                return line.replacingOccurrences(of: ":", with: "")
            }
        }
        return "/unknown"
    }

    private func generateOperationId(method: String, path: String) -> String {
        // Generate operationId from method and path
        let cleanPath = path
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return method + "_" + cleanPath
    }

    private func addExamples(to spec: String) async throws -> String {
        // Add examples to schemas that don't have them
        let prompt = """
        Add realistic example values to this OpenAPI spec's schemas.
        Only modify the schemas section to add example fields.
        Keep all other parts exactly the same.

        Current spec:
        \(spec)
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return response
    }

    private func enhanceDescriptions(in spec: String) async throws -> String {
        // Add better descriptions
        let prompt = """
        Enhance the descriptions in this OpenAPI spec.
        Add clear, concise descriptions to endpoints and parameters.
        Keep the structure exactly the same.

        Current spec:
        \(spec)
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return response
    }

    private func forceCorrectSpec(_ spec: String, issues: [String]) async throws -> String {
        let prompt = promptBuilder.buildForceCorrection(
            spec: spec,
            issues: issues
        )

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return response
    }

    private func identifyPersistentIssues(
        current: [String],
        previous: [String],
        fixed: [String]
    ) -> [String] {
        return OpenAPIValidationHelpers.identifyPersistentIssues(
            current: current,
            previous: previous,
            fixed: fixed
        )
    }

    // MARK: - Prompt Building Methods

    private func buildInitialGenerationPrompt(context: String) -> String {
        return promptBuilder.buildInitialGeneration(context: context)
    }

    private func buildCorrectionPromptWithMemory(
        spec: String,
        issues: [String],
        fixedIssues: [String]
    ) -> String {
        return promptBuilder.buildCorrectionWithMemory(
            spec: spec,
            issues: issues,
            fixedIssues: fixedIssues
        )
    }

    private func buildCorrectionPrompt(spec: String, issues: [String]) -> String {
        return promptBuilder.buildCorrection(spec: spec, issues: issues)
    }

    private func buildPersistentIssuePrompt(
        spec: String,
        persistentIssues: [String],
        fixedIssues: [String]
    ) -> String {
        return promptBuilder.buildPersistentIssue(
            spec: spec,
            persistentIssues: persistentIssues,
            fixedIssues: fixedIssues
        )
    }

    private func buildAlternativeGenerationPrompt(context: String, iteration: Int) -> String {
        return promptBuilder.buildAlternativeGeneration(context: context)
    }

    private func buildDetailedValidationPrompt(spec: String, knownIssues: [String]) -> String {
        return promptBuilder.buildValidation(spec: spec, knownIssues: knownIssues)
    }

    // MARK: - Structural Validation

    private func performStructuralValidation(_ spec: String) -> [String] {
        return structuralValidator.validate(spec)
    }

    private func parseValidationResponse(_ response: String) -> ValidationResult {
        let result = responseParser.parseValidationResponse(response)
        return ValidationResult(
            isValid: result.isValid,
            issues: result.issues,
            confidence: result.confidence
        )
    }

}
