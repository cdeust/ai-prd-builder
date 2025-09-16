import Foundation

/// Constants for OpenAPI Template System
public enum OpenAPITemplateConstants {

    // MARK: - Base Template

    public static let baseTemplate = """
    openapi: 3.1.0
    info:
      title: <SERVICE_TITLE>
      version: <SEMVER>
      description: <ONE_SENTENCE_DESCRIPTION>
    servers:
      - url: <HTTPS_URL>
        description: Production
    paths:
    <PATHS_BLOCK>
    components:
      schemas:
    <SCHEMAS_BLOCK>
        Error:
          type: object
          required: [message, code]
          properties:
            message:
              type: string
              description: Human-readable error message
              example: "Resource not found"
            code:
              type: string
              description: Machine-readable error code
              example: "NOT_FOUND"
            details:
              type: object
              description: Additional error details
              additionalProperties: true
      securitySchemes:
        BearerAuth:
          type: http
          scheme: bearer
          bearerFormat: JWT
    security:
      - BearerAuth: []
    """

    // MARK: - Path Template

    public static let pathTemplate = """
      /<resPlural>:
        get:
          summary: List <ResPluralPascal>
          operationId: list<ResPluralPascal>
          parameters:
            - name: page
              in: query
              required: false
              schema: { type: integer, minimum: 1 }
            - name: pageSize
              in: query
              required: false
              schema: { type: integer, minimum: 1, maximum: 100 }
          responses:
            '200':
              description: OK
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/<Res>List'
            '400':
              description: Bad Request
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
        post:
          summary: Create <Res>
          operationId: create<ResPascal>
          requestBody:
            required: true
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/<Res>Create'
          responses:
            '201':
              description: Created
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/<Res>'
            '400':
              description: Bad Request
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
      /<resPlural>/{id}:
        parameters:
          - name: id
            in: path
            required: true
            description: <Res> identifier
            schema: { type: string }
        get:
          summary: Get <Res> by id
          operationId: get<ResPascal>
          responses:
            '200':
              description: OK
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/<Res>'
            '404':
              description: Not Found
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
        put:
          summary: Replace <Res>
          operationId: replace<ResPascal>
          requestBody:
            required: true
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/<Res>Update'
          responses:
            '200':
              description: OK
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/<Res>'
            '404':
              description: Not Found
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '400':
              description: Bad Request
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
        patch:
          summary: Update <Res> fields
          operationId: update<ResPascal>
          requestBody:
            required: true
            content:
              application/json:
                schema:
                  $ref: '#/components/schemas/<Res>Patch'
          responses:
            '200':
              description: OK
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/<Res>'
            '404':
              description: Not Found
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '400':
              description: Bad Request
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
        delete:
          summary: Delete <Res>
          operationId: delete<ResPascal>
          responses:
            '204':
              description: No Content
            '404':
              description: Not Found
              content:
                application/json:
                  schema:
                    $ref: '#/components/schemas/Error'
            '401':
              description: Unauthorized
    """

    // MARK: - Schema Template

    public static let schemaTemplate = """
        <Res>:
          type: object
          required: [<REQUIRED_FIELDS>]
          properties:
    <PROPERTIES>
        <Res>List:
          type: object
          required: [items, totalCount, page, pageSize]
          properties:
            items:
              type: array
              items:
                $ref: '#/components/schemas/<Res>'
            totalCount:
              type: integer
              description: Total number of items
            page:
              type: integer
              description: Current page number
            pageSize:
              type: integer
              description: Number of items per page
        <Res>Create:
          type: object
          required: [name]
          properties:
            name:
              type: string
              minLength: 1
              maxLength: 255
            description:
              type: string
              maxLength: 1000
        <Res>Update:
          type: object
          required: [name]
          properties:
            name:
              type: string
              minLength: 1
              maxLength: 255
            description:
              type: string
              maxLength: 1000
        <Res>Patch:
          type: object
          properties:
            name:
              type: string
              minLength: 1
              maxLength: 255
            description:
              type: string
              maxLength: 1000
    """

    // MARK: - Common Schemas

    public static let commonSchemas = """
        Error:
          type: object
          required: [message, code]
          properties:
            message:
              type: string
              description: Human-readable error message
            code:
              type: string
              description: Machine-readable error code
            details:
              type: object
              description: Additional error details
    """

    // MARK: - Resource Block Template

    public static let resourceBlockTemplate = """
    # Resource: <Res>
    # This block defines all endpoints for managing <resPlural>
    """

    // MARK: - Placeholders

    public enum Placeholders {
        public static let serviceTitle = "<SERVICE_TITLE>"
        public static let semver = "<SEMVER>"
        public static let description = "<ONE_SENTENCE_DESCRIPTION>"
        public static let serverUrl = "<HTTPS_URL>"
        public static let pathsBlock = "<PATHS_BLOCK>"
        public static let schemasBlock = "<SCHEMAS_BLOCK>"
        public static let resPlural = "<resPlural>"
        public static let resPluralPascal = "<ResPluralPascal>"
        public static let res = "<Res>"
        public static let resPascal = "<ResPascal>"
        public static let properties = "<PROPERTIES>"
        public static let requiredFields = "<REQUIRED_FIELDS>"
    }

    // MARK: - Default Values

    public enum Defaults {
        public static let version = "1.0.0"
        public static let serverUrl = "https://api.example.com"
        public static let defaultTitle = "API Service"
        public static let defaultDescription = "RESTful API for resource management"
    }

    // MARK: - Validation Patterns

    public enum ValidationPatterns {
        public static let semverPattern = #"^\d+\.\d+\.\d+$"#
        public static let urlPattern = #"^https?://[\w\.\-]+(/[\w\.\-]*)*$"#
        public static let identifierPattern = #"^[a-zA-Z][a-zA-Z0-9_]*$"#
    }
}