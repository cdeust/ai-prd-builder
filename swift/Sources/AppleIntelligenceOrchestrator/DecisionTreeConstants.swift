import Foundation

/// Constants for Decision Tree operations
public enum DecisionTreeConstants {

    // MARK: - Categories
    public enum Categories {
        public static let root = "root"
        public static let structural = "structural"
        public static let security = "security"
        public static let schema = "schema"
        public static let operations = "operations"
        public static let constraint = "constraint"
    }

    // MARK: - Issues
    public enum Issues {
        // Structural
        public static let structural = "structural"
        public static let missingOpenapiVersion = "missing openapi version"
        public static let missingInfoSection = "missing info section"
        public static let missingPaths = "missing paths"
        public static let duplicatePath = "duplicate path"
        public static let invalidHttpMethod = "invalid http method"

        // Security
        public static let security = "security"
        public static let missingSecurityScheme = "missing security scheme"
        public static let undefinedSecurityReference = "undefined security reference"
        public static let bearerToken = "bearer token"
        public static let apiKey = "api key"

        // Schema
        public static let schema = "schema"
        public static let missingSchemaType = "missing schema type"
        public static let missingRequiredProperties = "missing required properties"
        public static let invalidRef = "invalid $ref"
        public static let missingExample = "missing example"
        public static let arrayWithoutItems = "array without items"

        // Operations
        public static let operation = "operation"
        public static let missingOperationId = "missing operationid"
        public static let missingResponses = "missing responses"
        public static let missing200Response = "missing 200 response"
        public static let missingErrorResponses = "missing error responses"
        public static let missingRequestBody = "missing request body"
    }

    // MARK: - Solutions
    public enum Solutions {
        // Root
        public static let reviewStructure = "Review OpenAPI structure"
        public static let reviewSecurity = "Review security definitions"
        public static let reviewSchemas = "Review schema definitions"
        public static let reviewOperations = "Review operation definitions"

        // Structural
        public static let addOpenapiVersion = "Add 'openapi: 3.1.0' at the top of the specification"
        public static let addInfoSection = "Add 'info:' section with title and version"
        public static let addPathsSection = "Add 'paths:' section with at least one endpoint"
        public static let mergeduplicatePaths = "Ensure each path is unique or merge duplicate definitions"
        public static let useValidHttpMethods = "Use valid HTTP methods: get, post, put, patch, delete, head, options"

        // Security
        public static let addSecurityScheme = "Add security scheme definition in components/securitySchemes"
        public static let matchSecurityReferences = "Ensure security references match defined schemes"
        public static let defineBearerToken = "Define Bearer token scheme: type: http, scheme: bearer"
        public static let defineApiKey = "Define API key scheme with name and in (header/query/cookie)"

        // Schema
        public static let addSchemaType = "Add 'type' property to schema (object, array, string, number, boolean)"
        public static let addRequiredArray = "Add 'required' array for object schemas with mandatory fields"
        public static let fixRefPointer = "Ensure $ref points to existing component: '#/components/schemas/ModelName'"
        public static let addExample = "Add 'example' field to improve documentation"
        public static let addItemsProperty = "Add 'items' property to define array element type"

        // Operations
        public static let addOperationId = "Add unique 'operationId' to each operation"
        public static let addResponses = "Add 'responses' section with at least one status code"
        public static let add200Response = "Add '200' response for successful operations"
        public static let addErrorResponses = "Add error responses (400, 401, 403, 404, 500)"
        public static let addRequestBody = "Add 'requestBody' with content type and schema"
    }

    // MARK: - Confidence Values
    public enum Confidence {
        public static let rootNode = 1.0
        public static let structural = 0.9
        public static let security = 0.85
        public static let schema = 0.8
        public static let operations = 0.85

        // Specific nodes
        public static let versionNode = 1.0
        public static let infoNode = 1.0
        public static let pathsNode = 1.0
        public static let duplicatePathNode = 0.95
        public static let invalidMethodNode = 1.0
        public static let missingSecuritySchemeNode = 0.95
        public static let undefinedSecurityNode = 0.9
        public static let bearerTokenNode = 1.0
        public static let apiKeyNode = 1.0
        public static let missingTypeNode = 0.95
        public static let missingRequiredNode = 0.9
        public static let invalidRefNode = 0.95
        public static let missingExampleNode = 0.7
        public static let arrayItemsNode = 1.0
        public static let operationIdNode = 0.95
        public static let responsesNode = 1.0
        public static let response200Node = 0.9
        public static let errorResponsesNode = 0.8
        public static let requestBodyNode = 0.85
    }

    // MARK: - HTTP Methods
    public enum HTTPMethods {
        public static let all = ["get", "post", "put", "patch", "delete", "head", "options"]
        public static let commonMethods = ["get", "post", "put", "delete", "patch"]

        public static func isValid(_ method: String) -> Bool {
            return all.contains(method.lowercased())
        }
    }

    // MARK: - Status Codes
    public enum StatusCodes {
        public static let success = "200"
        public static let created = "201"
        public static let noContent = "204"
        public static let badRequest = "400"
        public static let unauthorized = "401"
        public static let forbidden = "403"
        public static let notFound = "404"
        public static let internalError = "500"

        public static let standardErrors = ["400", "401", "403", "404", "500"]
        public static let allStandard = ["200", "201", "204", "400", "401", "403", "404", "500"]
    }
}