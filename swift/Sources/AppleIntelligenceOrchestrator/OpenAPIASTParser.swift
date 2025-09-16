import Foundation

/// Abstract Syntax Tree parser for OpenAPI specifications
public class OpenAPIASTParser {

    // MARK: - Public Interface

    public func parse(_ specification: String) throws -> OpenAPIAST {
        let ast = OpenAPIAST()
        let lines = specification.components(separatedBy: .newlines)

        var context = ParsingContext()

        for (index, line) in lines.enumerated() {
            let node = try parseLine(
                line,
                lineNumber: index + 1,
                context: &context
            )

            if let node = node {
                ast.addNode(node)
                updateContext(&context, with: node, line: line)
            }
        }

        return ast
    }

    // MARK: - Parsing Methods

    private func parseLine(
        _ line: String,
        lineNumber: Int,
        context: inout ParsingContext
    ) throws -> ASTNode? {

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let indentation = calculateIndentation(line)
        updateContextPath(&context, indentation: indentation)

        return try parseKeyValue(trimmed, lineNumber: lineNumber, context: context)
    }

    private func parseKeyValue(
        _ line: String,
        lineNumber: Int,
        context: ParsingContext
    ) throws -> ASTNode? {

        guard let colonIndex = line.firstIndex(of: ":") else {
            return nil
        }

        let key = extractKey(from: line, colonIndex: colonIndex)
        let value = extractValue(from: line, colonIndex: colonIndex)

        return ASTNode(
            type: determineNodeType(key: key, path: context.path),
            key: key,
            value: value.isEmpty ? nil : value,
            path: context.path,
            line: lineNumber
        )
    }

    // MARK: - Helper Methods

    private func calculateIndentation(_ line: String) -> Int {
        line.prefix(while: { $0 == " " }).count / OpenAPIValidationConstants.AST.indentationUnit
    }

    private func extractKey(from line: String, colonIndex: String.Index) -> String {
        String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
    }

    private func extractValue(from line: String, colonIndex: String.Index) -> String {
        String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
    }

    private func determineNodeType(key: String, path: [String]) -> ASTNodeType {
        switch key {
        case OpenAPIValidationConstants.AST.versionKey:
            return .version
        case OpenAPIValidationConstants.AST.infoKey:
            return .info
        case OpenAPIValidationConstants.AST.pathsKey:
            return .paths
        case OpenAPIValidationConstants.AST.componentsKey:
            return .components
        case OpenAPIValidationConstants.AST.serversKey:
            return .servers
        case _ where path.contains(OpenAPIValidationConstants.AST.pathsKey):
            return .operation
        case _ where path.contains(OpenAPIValidationConstants.AST.schemasKey):
            return .schema
        default:
            return .property
        }
    }

    private func updateContextPath(
        _ context: inout ParsingContext,
        indentation: Int
    ) {
        // Adjust path based on indentation
        while context.indentStack.count > 1 &&
              indentation <= context.indentStack[context.indentStack.count - 2] {
            context.path.removeLast()
            context.indentStack.removeLast()
        }
    }

    private func updateContext(
        _ context: inout ParsingContext,
        with node: ASTNode,
        line: String
    ) {
        if node.value == nil {
            // This is a parent node
            context.path.append(node.key)
            let indentation = calculateIndentation(line)
            context.indentStack.append(indentation)
        }
    }
}


