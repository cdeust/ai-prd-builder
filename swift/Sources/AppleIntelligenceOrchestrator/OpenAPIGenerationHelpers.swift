import Foundation

/// Helper methods for OpenAPI generation operations
public class OpenAPIGenerationHelpers {

    // MARK: - Path and Operation ID Generation

    /// Generate operation ID from method and path
    public static func generateOperationId(method: String, path: String) -> String {
        let cleanPath = path
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return method + "_" + cleanPath
    }

    /// Find the path for an operation at a given index
    public static func findPathForOperation(at index: Int, in lines: [String]) -> String {
        // Look backwards for the path definition
        for i in stride(from: index - 1, to: 0, by: -1) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("/") && line.hasSuffix(":") {
                return line.replacingOccurrences(of: ":", with: "")
            }
        }
        return "/unknown"
    }

    // MARK: - String Transformations

    /// Convert text to PascalCase
    public static func toPascalCase(_ text: String) -> String {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return words
            .filter { !$0.isEmpty }
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined()
    }

    /// Pluralize a word using simple rules
    public static func pluralize(_ word: String) -> String {
        let lowercased = word.lowercased()

        // Special cases
        let irregulars = [
            "person": "people",
            "child": "children",
            "man": "men",
            "woman": "women"
        ]

        if let irregular = irregulars[lowercased] {
            return irregular
        }

        // Regular rules
        if word.hasSuffix("y") && !isVowel(word.dropLast().last ?? " ") {
            return String(word.dropLast()) + "ies"
        } else if word.hasSuffix("s") || word.hasSuffix("x") ||
                  word.hasSuffix("ch") || word.hasSuffix("sh") {
            return word + "es"
        } else {
            return word + "s"
        }
    }

    private static func isVowel(_ char: Character) -> Bool {
        return "aeiouAEIOU".contains(char)
    }

    // MARK: - Type Mapping

    /// Map common type names to OpenAPI types
    public static func mapToOpenAPIType(_ type: String) -> (type: String, format: String?) {
        switch type.lowercased() {
        case "string", "text", "varchar", "char":
            return ("string", nil)
        case "int", "integer", "int32":
            return ("integer", "int32")
        case "long", "int64", "bigint":
            return ("integer", "int64")
        case "float", "real":
            return ("number", "float")
        case "double", "decimal", "numeric":
            return ("number", "double")
        case "bool", "boolean", "bit":
            return ("boolean", nil)
        case "date":
            return ("string", "date")
        case "datetime", "timestamp", "time":
            return ("string", "date-time")
        case "uuid", "guid":
            return ("string", "uuid")
        case "email":
            return ("string", "email")
        case "url", "uri":
            return ("string", "uri")
        case "array", "list":
            return ("array", nil)
        case "object", "dict", "dictionary", "map":
            return ("object", nil)
        default:
            return ("string", nil)
        }
    }

    // MARK: - Structure Validation

    /// Check if a specification has valid template structure
    public static func hasValidTemplateStructure(_ spec: String) -> Bool {
        let requiredSections = [
            "openapi:",
            "info:",
            "paths:",
            "components:",
            "schemas:"
        ]

        return requiredSections.allSatisfy { spec.contains($0) }
    }

    /// Check if a line is an HTTP method definition
    public static func isHTTPMethodLine(_ line: String) -> Bool {
        let methods = ["get:", "post:", "put:", "patch:", "delete:", "options:", "head:"]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return methods.contains(trimmed)
    }

    // MARK: - Issue Detection

    /// Check if operation has an operation ID
    public static func hasOperationId(after index: Int, in lines: [String]) -> Bool {
        guard index + 2 < lines.count else { return false }

        for i in (index + 1)..<min(index + 5, lines.count) {
            if lines[i].contains("operationId:") {
                return true
            }
            // Stop if we hit another operation or path
            if isHTTPMethodLine(lines[i]) || lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("/") {
                break
            }
        }

        return false
    }

    // MARK: - Default Values

    /// Generate default properties for a resource
    public static func generateDefaultProperties(for resourceName: String) -> [OpenAPIProperty] {
        var properties = [
            OpenAPIProperty(
                name: "id",
                type: "string",
                required: true,
                format: "uuid"
            ),
            OpenAPIProperty(
                name: "createdAt",
                type: "string",
                required: true,
                format: "date-time"
            ),
            OpenAPIProperty(
                name: "updatedAt",
                type: "string",
                required: false,
                format: "date-time"
            )
        ]

        // Add name property if not a special resource
        if !["user", "session", "token"].contains(resourceName.lowercased()) {
            properties.insert(
                OpenAPIProperty(
                    name: "name",
                    type: "string",
                    required: true,
                    format: nil
                ),
                at: 1
            )
        }

        // Add description for most resources
        properties.append(
            OpenAPIProperty(
                name: "description",
                type: "string",
                required: false,
                format: nil
            )
        )

        return properties
    }
}