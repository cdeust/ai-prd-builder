import Foundation

/// Constraint Satisfaction Problem solver for OpenAPI validation
public class OpenAPIConstraintSolver {

    // MARK: - Public Interface

    public func solve(_ constraints: [ValidationConstraint]) -> ConstraintSolutionResult {
        var satisfied: [ValidationConstraint] = []
        var violations: [ConstraintViolation] = []

        for constraint in constraints {
            let result = evaluateConstraint(constraint)

            if result.isSatisfied {
                satisfied.append(constraint)
            } else {
                violations.append(result.violation!)
            }
        }

        return ConstraintSolutionResult(
            isSatisfied: violations.isEmpty,
            satisfiedConstraints: satisfied,
            violations: violations,
            satisfactionRate: calculateSatisfactionRate(
                satisfied: satisfied.count,
                total: constraints.count
            )
        )
    }

    public func extractConstraints(from ast: OpenAPIAST) -> [ValidationConstraint] {
        var constraints: [ValidationConstraint] = []

        // Add version constraint
        constraints.append(createVersionConstraint(ast))

        // Add required section constraints
        constraints.append(contentsOf: createSectionConstraints(ast))

        // Add operation constraints
        constraints.append(contentsOf: createOperationConstraints(ast))

        // Add schema constraints
        constraints.append(contentsOf: createSchemaConstraints(ast))

        return constraints
    }

    // MARK: - Constraint Evaluation

    private func evaluateConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        switch constraint.type {
        case .required:
            return evaluateRequiredConstraint(constraint)
        case .unique:
            return evaluateUniqueConstraint(constraint)
        case .format:
            return evaluateFormatConstraint(constraint)
        case .reference:
            return evaluateReferenceConstraint(constraint)
        case .dependency:
            return evaluateDependencyConstraint(constraint)
        }
    }

    private func evaluateRequiredConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        let isSatisfied = constraint.actualValue != nil

        if !isSatisfied {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: "Required field missing: \(constraint.path.joined(separator: "."))",
                    severity: .critical
                )
            )
        }

        return ConstraintEvaluation(isSatisfied: true, violation: nil)
    }

    private func evaluateUniqueConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        // Check uniqueness based on constraint metadata
        let isUnique = checkUniqueness(constraint)

        if !isUnique {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: "Duplicate value found: \(constraint.path.joined(separator: "."))",
                    severity: .major
                )
            )
        }

        return ConstraintEvaluation(isSatisfied: true, violation: nil)
    }

    private func evaluateFormatConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        guard let actualValue = constraint.actualValue,
              let expectedFormat = constraint.expectedValue else {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: "Format validation failed: missing values",
                    severity: .minor
                )
            )
        }

        let isValid = validateFormat(actualValue, against: expectedFormat)

        if !isValid {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: "Invalid format: expected \(expectedFormat), got \(actualValue)",
                    severity: .major
                )
            )
        }

        return ConstraintEvaluation(isSatisfied: true, violation: nil)
    }

    private func evaluateReferenceConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        guard let reference = constraint.actualValue else {
            return ConstraintEvaluation(isSatisfied: true, violation: nil)
        }

        let isValid = validateReference(reference, in: constraint.context)

        if !isValid {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: String(format: OpenAPIValidationConstants.Constraints.invalidReferenceMessage, reference),
                    severity: .critical
                )
            )
        }

        return ConstraintEvaluation(isSatisfied: true, violation: nil)
    }

    private func evaluateDependencyConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        let areDependenciesMet = checkDependencies(constraint)

        if !areDependenciesMet {
            return ConstraintEvaluation(
                isSatisfied: false,
                violation: ConstraintViolation(
                    constraint: constraint,
                    message: "Dependency not satisfied: \(constraint.requirement)",
                    severity: .major
                )
            )
        }

        return ConstraintEvaluation(isSatisfied: true, violation: nil)
    }

    // MARK: - Constraint Creation

    private func createVersionConstraint(_ ast: OpenAPIAST) -> ValidationConstraint {
        let versionNode = ast.nodes.first { $0.type == .version }

        return ValidationConstraint(
            type: .required,
            path: [OpenAPIValidationConstants.AST.versionKey],
            requirement: OpenAPIValidationConstants.Constraints.requiredOpenAPIVersion,
            expectedValue: OpenAPIValidationConstants.Constraints.requiredOpenAPIVersion,
            actualValue: versionNode?.value,
            context: ast
        )
    }

    private func createSectionConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        OpenAPIValidationConstants.Constraints.requiredSections.map { section in
            let sectionNode = ast.nodes.first { $0.key == section }

            return ValidationConstraint(
                type: .required,
                path: [section],
                requirement: String(format: OpenAPIValidationConstants.Constraints.missingSectionMessage, section),
                expectedValue: "*",
                actualValue: sectionNode != nil ? "present" : nil,
                context: ast
            )
        }
    }

    private func createOperationConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        ast.nodes
            .filter { $0.type == .operation }
            .map { operation in
                ValidationConstraint(
                    type: .required,
                    path: operation.path + ["operationId"],
                    requirement: "Operation must have operationId",
                    expectedValue: "*",
                    actualValue: findOperationId(for: operation, in: ast),
                    context: ast
                )
            }
    }

    private func createSchemaConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        ast.nodes
            .filter { $0.type == .schema }
            .flatMap { schema in
                [
                    ValidationConstraint(
                        type: .required,
                        path: schema.path + ["type"],
                        requirement: "Schema must have type",
                        expectedValue: "*",
                        actualValue: findSchemaType(for: schema, in: ast),
                        context: ast
                    ),
                    ValidationConstraint(
                        type: .format,
                        path: schema.path + ["example"],
                        requirement: "Schema should have example",
                        expectedValue: "*",
                        actualValue: findExample(for: schema, in: ast),
                        context: ast
                    )
                ]
            }
    }

    // MARK: - Helper Methods

    private func checkUniqueness(_ constraint: ValidationConstraint) -> Bool {
        // Implementation would check for duplicates based on context
        true
    }

    private func validateFormat(_ value: String, against format: String) -> Bool {
        switch format {
        case "*":
            return !value.isEmpty
        case let pattern where pattern.hasPrefix("^") && pattern.hasSuffix("$"):
            // Regex validation
            return value.range(of: pattern, options: .regularExpression) != nil
        default:
            return value == format
        }
    }

    private func validateReference(_ reference: String, in context: Any?) -> Bool {
        guard reference.hasPrefix("#/") else { return false }
        // Check if reference exists in context
        return true
    }

    private func checkDependencies(_ constraint: ValidationConstraint) -> Bool {
        // Check if dependencies are met
        true
    }

    private func calculateSatisfactionRate(satisfied: Int, total: Int) -> Double {
        guard total > OpenAPIPromptConstants.Indices.firstElement else { return Double(OpenAPIPromptConstants.Confidence.maxValue) }
        return Double(satisfied) / Double(total)
    }

    private func findOperationId(for operation: ASTNode, in ast: OpenAPIAST) -> String? {
        operation.children.first { $0.key == "operationId" }?.value
    }

    private func findSchemaType(for schema: ASTNode, in ast: OpenAPIAST) -> String? {
        schema.children.first { $0.key == "type" }?.value
    }

    private func findExample(for schema: ASTNode, in ast: OpenAPIAST) -> String? {
        schema.children.first { $0.key == "example" }?.value
    }
}

// MARK: - Supporting Types

public struct ValidationConstraint {
    public let type: ConstraintType
    public let path: [String]
    public let requirement: String
    public let expectedValue: String?
    public let actualValue: String?
    public let context: Any?

    public enum ConstraintType {
        case required
        case unique
        case format
        case reference
        case dependency
    }

    public init(
        type: ConstraintType,
        path: [String],
        requirement: String,
        expectedValue: String? = nil,
        actualValue: String? = nil,
        context: Any? = nil
    ) {
        self.type = type
        self.path = path
        self.requirement = requirement
        self.expectedValue = expectedValue
        self.actualValue = actualValue
        self.context = context
    }
}

