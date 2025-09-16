import Foundation

/// Builds decision trees for OpenAPI issue resolution
public class DecisionTreeBuilder {

    // MARK: - Public Interface

    public static func buildTree() -> OpenAPIDecisionNode {
        let root = createRootNode()

        root.children = [
            buildStructuralBranch(),
            buildSecurityBranch(),
            buildSchemaBranch(),
            buildOperationsBranch()
        ]

        return root
    }

    // MARK: - Root Node

    private static func createRootNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.root,
            issue: "",
            solution: "",
            confidence: DecisionTreeConstants.Confidence.rootNode
        )
    }

    // MARK: - Structural Branch

    private static func buildStructuralBranch() -> OpenAPIDecisionNode {
        let structural = OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.structural,
            solution: DecisionTreeConstants.Solutions.reviewStructure,
            confidence: DecisionTreeConstants.Confidence.structural
        )

        structural.children = [
            createVersionNode(),
            createInfoSectionNode(),
            createPathsSectionNode(),
            createDuplicatePathNode(),
            createInvalidMethodNode()
        ]

        return structural
    }

    private static func createVersionNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.missingOpenapiVersion,
            solution: DecisionTreeConstants.Solutions.addOpenapiVersion,
            confidence: DecisionTreeConstants.Confidence.versionNode
        )
    }

    private static func createInfoSectionNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.missingInfoSection,
            solution: DecisionTreeConstants.Solutions.addInfoSection,
            confidence: DecisionTreeConstants.Confidence.infoNode
        )
    }

    private static func createPathsSectionNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.missingPaths,
            solution: DecisionTreeConstants.Solutions.addPathsSection,
            confidence: DecisionTreeConstants.Confidence.pathsNode
        )
    }

    private static func createDuplicatePathNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.duplicatePath,
            solution: DecisionTreeConstants.Solutions.mergeduplicatePaths,
            confidence: DecisionTreeConstants.Confidence.duplicatePathNode
        )
    }

    private static func createInvalidMethodNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.structural,
            issue: DecisionTreeConstants.Issues.invalidHttpMethod,
            solution: DecisionTreeConstants.Solutions.useValidHttpMethods,
            confidence: DecisionTreeConstants.Confidence.invalidMethodNode
        )
    }

    // MARK: - Security Branch

    private static func buildSecurityBranch() -> OpenAPIDecisionNode {
        let security = OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.security,
            issue: DecisionTreeConstants.Issues.security,
            solution: DecisionTreeConstants.Solutions.reviewSecurity,
            confidence: DecisionTreeConstants.Confidence.security
        )

        security.children = [
            createMissingSecuritySchemeNode(),
            createUndefinedSecurityNode(),
            createBearerTokenNode(),
            createApiKeyNode()
        ]

        return security
    }

    private static func createMissingSecuritySchemeNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.security,
            issue: DecisionTreeConstants.Issues.missingSecurityScheme,
            solution: DecisionTreeConstants.Solutions.addSecurityScheme,
            confidence: DecisionTreeConstants.Confidence.missingSecuritySchemeNode
        )
    }

    private static func createUndefinedSecurityNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.security,
            issue: DecisionTreeConstants.Issues.undefinedSecurityReference,
            solution: DecisionTreeConstants.Solutions.matchSecurityReferences,
            confidence: DecisionTreeConstants.Confidence.undefinedSecurityNode
        )
    }

    private static func createBearerTokenNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.security,
            issue: DecisionTreeConstants.Issues.bearerToken,
            solution: DecisionTreeConstants.Solutions.defineBearerToken,
            confidence: DecisionTreeConstants.Confidence.bearerTokenNode
        )
    }

    private static func createApiKeyNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.security,
            issue: DecisionTreeConstants.Issues.apiKey,
            solution: DecisionTreeConstants.Solutions.defineApiKey,
            confidence: DecisionTreeConstants.Confidence.apiKeyNode
        )
    }

    // MARK: - Schema Branch

    private static func buildSchemaBranch() -> OpenAPIDecisionNode {
        let schema = OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.schema,
            solution: DecisionTreeConstants.Solutions.reviewSchemas,
            confidence: DecisionTreeConstants.Confidence.schema
        )

        schema.children = [
            createMissingTypeNode(),
            createMissingRequiredNode(),
            createInvalidRefNode(),
            createMissingExampleNode(),
            createArrayWithoutItemsNode()
        ]

        return schema
    }

    private static func createMissingTypeNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.missingSchemaType,
            solution: DecisionTreeConstants.Solutions.addSchemaType,
            confidence: DecisionTreeConstants.Confidence.missingTypeNode
        )
    }

    private static func createMissingRequiredNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.missingRequiredProperties,
            solution: DecisionTreeConstants.Solutions.addRequiredArray,
            confidence: DecisionTreeConstants.Confidence.missingRequiredNode
        )
    }

    private static func createInvalidRefNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.invalidRef,
            solution: DecisionTreeConstants.Solutions.fixRefPointer,
            confidence: DecisionTreeConstants.Confidence.invalidRefNode
        )
    }

    private static func createMissingExampleNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.missingExample,
            solution: DecisionTreeConstants.Solutions.addExample,
            confidence: DecisionTreeConstants.Confidence.missingExampleNode
        )
    }

    private static func createArrayWithoutItemsNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.schema,
            issue: DecisionTreeConstants.Issues.arrayWithoutItems,
            solution: DecisionTreeConstants.Solutions.addItemsProperty,
            confidence: DecisionTreeConstants.Confidence.arrayItemsNode
        )
    }

    // MARK: - Operations Branch

    private static func buildOperationsBranch() -> OpenAPIDecisionNode {
        let operations = OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.operation,
            solution: DecisionTreeConstants.Solutions.reviewOperations,
            confidence: DecisionTreeConstants.Confidence.operations
        )

        operations.children = [
            createMissingOperationIdNode(),
            createMissingResponsesNode(),
            createMissing200ResponseNode(),
            createMissingErrorResponsesNode(),
            createMissingRequestBodyNode()
        ]

        return operations
    }

    private static func createMissingOperationIdNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.missingOperationId,
            solution: DecisionTreeConstants.Solutions.addOperationId,
            confidence: DecisionTreeConstants.Confidence.operationIdNode
        )
    }

    private static func createMissingResponsesNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.missingResponses,
            solution: DecisionTreeConstants.Solutions.addResponses,
            confidence: DecisionTreeConstants.Confidence.responsesNode
        )
    }

    private static func createMissing200ResponseNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.missing200Response,
            solution: DecisionTreeConstants.Solutions.add200Response,
            confidence: DecisionTreeConstants.Confidence.response200Node
        )
    }

    private static func createMissingErrorResponsesNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.missingErrorResponses,
            solution: DecisionTreeConstants.Solutions.addErrorResponses,
            confidence: DecisionTreeConstants.Confidence.errorResponsesNode
        )
    }

    private static func createMissingRequestBodyNode() -> OpenAPIDecisionNode {
        return OpenAPIDecisionNode(
            category: DecisionTreeConstants.Categories.operations,
            issue: DecisionTreeConstants.Issues.missingRequestBody,
            solution: DecisionTreeConstants.Solutions.addRequestBody,
            confidence: DecisionTreeConstants.Confidence.requestBodyNode
        )
    }
}