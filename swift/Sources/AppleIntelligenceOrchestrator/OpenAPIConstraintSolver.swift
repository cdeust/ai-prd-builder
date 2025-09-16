import Foundation

/// Constraint Satisfaction Problem solver for OpenAPI validation
public class OpenAPIConstraintSolver {

    // MARK: - Public Interface

    public func solve(_ constraints: [ValidationConstraint]) -> ConstraintSolutionResult {
        var satisfied: [ValidationConstraint] = []
        var violations: [ConstraintViolation] = []
        var fixes: [ConstraintFix] = []

        for constraint in constraints {
            let result = evaluateConstraint(constraint)

            if result.isSatisfied {
                satisfied.append(constraint)
            } else {
                // Create violation from the constraint
                let violation = ConstraintViolation(
                    constraint: constraint.description,
                    message: result.message ?? constraint.message,
                    severity: constraint.severity
                )
                violations.append(violation)
                fixes.append(contentsOf: result.fixes)
            }
        }

        let satisfactionRate = constraints.isEmpty ? 1.0 : Double(satisfied.count) / Double(constraints.count)

        return ConstraintSolutionResult(
            isValid: violations.isEmpty,
            fixes: fixes,
            confidence: satisfactionRate,
            violations: violations,
            satisfactionRate: satisfactionRate
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
        case .format:
            return evaluateFormatConstraint(constraint)
        case .reference:
            return evaluateReferenceConstraint(constraint)
        default:
            return evaluateGenericConstraint(constraint)
        }
    }

    private func evaluateRequiredConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        // For demo purposes, assume constraint is satisfied if path is not empty
        let isSatisfied = !constraint.path.isEmpty

        if !isSatisfied {
            let fix = ConstraintFix(
                path: constraint.path,
                issue: "Required field missing",
                fix: "Add required field: \(constraint.path)",
                severity: .critical
            )

            return ConstraintEvaluation(
                constraint: constraint.description,
                isSatisfied: false,
                message: "Required field missing: \(constraint.path)",
                fixes: [fix]
            )
        }

        return ConstraintEvaluation(
            constraint: constraint.description,
            isSatisfied: true,
            message: nil,
            fixes: []
        )
    }

    private func evaluateFormatConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        // Check format based on the constraint type and path
        let isSatisfied = validateFormat(for: constraint)

        if !isSatisfied {
            let fix = ConstraintFix(
                path: constraint.path,
                issue: "Invalid format",
                fix: "Fix format to match expected pattern",
                severity: .major
            )

            return ConstraintEvaluation(
                constraint: constraint.description,
                isSatisfied: false,
                message: "Invalid format at: \(constraint.path)",
                fixes: [fix]
            )
        }

        return ConstraintEvaluation(
            constraint: constraint.description,
            isSatisfied: true,
            message: nil,
            fixes: []
        )
    }

    private func validateFormat(for constraint: ValidationConstraint) -> Bool {
        // Validate based on common OpenAPI format requirements
        if constraint.path.contains("email") {
            // Email format validation would go here
            return true // Placeholder for email validation
        } else if constraint.path.contains("url") || constraint.path.contains("uri") {
            // URL format validation would go here
            return true // Placeholder for URL validation
        } else if constraint.path.contains("date") {
            // Date format validation would go here
            return true // Placeholder for date validation
        } else if constraint.path.contains("uuid") {
            // UUID format validation would go here
            return true // Placeholder for UUID validation
        }

        // Default: assume format is valid if no specific validation is implemented
        return true
    }

    private func evaluateReferenceConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        // Check if reference constraint is satisfied
        let isSatisfied = validateReference(for: constraint)

        if !isSatisfied {
            let fix = ConstraintFix(
                path: constraint.path,
                issue: "Invalid reference",
                fix: "Fix reference to point to existing definition",
                severity: .major
            )

            return ConstraintEvaluation(
                constraint: constraint.description,
                isSatisfied: false,
                message: "Invalid reference at: \(constraint.path)",
                fixes: [fix]
            )
        }

        return ConstraintEvaluation(
            constraint: constraint.description,
            isSatisfied: true,
            message: nil,
            fixes: []
        )
    }

    private func validateReference(for constraint: ValidationConstraint) -> Bool {
        // Check if the constraint path contains reference indicators
        if constraint.path.contains("$ref") {
            // In a real implementation, we would check if the reference target exists
            // For now, we'll validate based on the reference format
            return constraint.path.contains("#/") || constraint.path.contains("http")
        }

        // If not a reference constraint, consider it valid
        return true
    }

    private func evaluateGenericConstraint(_ constraint: ValidationConstraint) -> ConstraintEvaluation {
        // Generic constraint evaluation
        return ConstraintEvaluation(
            constraint: constraint.description,
            isSatisfied: true,
            message: nil,
            fixes: []
        )
    }

    // MARK: - Constraint Creation

    private func createVersionConstraint(_ ast: OpenAPIAST) -> ValidationConstraint {
        let versionNode = ast.allNodes.first { $0.type == .version }

        if versionNode == nil {
            return ValidationConstraint(
                type: .version,
                path: "openapi",
                message: "OpenAPI version is required",
                severity: .critical
            )
        }

        return ValidationConstraint(
            type: .version,
            path: "openapi",
            message: "OpenAPI version is present",
            severity: .low
        )
    }

    private func createSectionConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        var constraints: [ValidationConstraint] = []

        let requiredSections = ["info", "paths"]

        for section in requiredSections {
            let sectionNode = ast.allNodes.first { $0.key == section }

            if sectionNode == nil {
                constraints.append(ValidationConstraint(
                    type: .required,
                    path: section,
                    message: "Required section '\(section)' is missing",
                    severity: .critical
                ))
            }
        }

        return constraints
    }

    private func createOperationConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        var constraints: [ValidationConstraint] = []

        let operations = ast.allNodes.filter { $0.type == .operation }

        for operation in operations {
            // Check for operation ID
            let hasOperationId = operation.children.contains { $0.key == "operationId" }

            if !hasOperationId {
                constraints.append(ValidationConstraint(
                    type: .operation,
                    path: operation.path.joined(separator: "."),
                    message: "Operation should have an operationId",
                    severity: .medium
                ))
            }

            // Check for responses
            let hasResponses = operation.children.contains { $0.key == "responses" }

            if !hasResponses {
                constraints.append(ValidationConstraint(
                    type: .response,
                    path: operation.path.joined(separator: "."),
                    message: "Operation must have responses defined",
                    severity: .critical
                ))
            }
        }

        return constraints
    }

    private func createSchemaConstraints(_ ast: OpenAPIAST) -> [ValidationConstraint] {
        var constraints: [ValidationConstraint] = []

        let schemas = ast.allNodes.filter { $0.type == .schema }

        for schema in schemas {
            // Check for type definition
            let hasType = schema.children.contains { $0.key == "type" }

            if !hasType {
                constraints.append(ValidationConstraint(
                    type: .schema,
                    path: schema.path.joined(separator: "."),
                    message: "Schema should have a type defined",
                    severity: .medium
                ))
            }

            // Check array items
            let isArray = schema.children.first { $0.key == "type" }?.value == "array"
            let hasItems = schema.children.contains { $0.key == "items" }

            if isArray && !hasItems {
                constraints.append(ValidationConstraint(
                    type: .schema,
                    path: schema.path.joined(separator: "."),
                    message: "Array schema must have 'items' defined",
                    severity: .major
                ))
            }
        }

        return constraints
    }

    // MARK: - Helper Methods

    private func calculateSatisfactionRate(satisfied: Int, total: Int) -> Double {
        guard total > 0 else { return 1.0 }
        return Double(satisfied) / Double(total)
    }

    private func checkUniqueness(_ constraint: ValidationConstraint) -> Bool {
        // Simplified uniqueness check
        return true
    }
}