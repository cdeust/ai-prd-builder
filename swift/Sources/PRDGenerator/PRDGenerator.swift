import Foundation
import CommonModels
import DomainCore
import ThinkingCore

/// Simplified PRD Generator that serves as a facade to the orchestration system
/// This class now follows Single Responsibility Principle - it only handles high-level coordination
public final class PRDGenerator: PRDGeneratorProtocol {
    private let orchestrator: PRDOrchestrator
    private let inputProcessor: InputProcessor
    private let documentAssembler: DocumentAssembler
    private let mockupDetector: MockupInputDetector

    /// Input structure supporting both text and mockups
    public struct PRDInput {
        public let text: String?
        public let mockupPaths: [String]
        public let guidelines: String?

        public init(text: String? = nil, mockupPaths: [String] = [], guidelines: String? = nil) {
            self.text = text
            self.mockupPaths = mockupPaths
            self.guidelines = guidelines
        }

        /// Convenience initializer for text-only input
        public static func text(_ input: String) -> PRDInput {
            return PRDInput(text: input)
        }
    }

    public init(
        provider: AIProvider,
        configuration: Configuration,
        interactionHandler: UserInteractionHandler? = nil
    ) {
        self.orchestrator = PRDOrchestrator(
            provider: provider,
            configuration: configuration,
            interactionHandler: interactionHandler
        )
        self.inputProcessor = InputProcessor(provider: provider, configuration: configuration)
        self.documentAssembler = DocumentAssembler()
        self.mockupDetector = MockupInputDetector()
    }

    // MARK: - Public API

    /// Generate PRD from raw string input with automatic mockup detection
    public func generatePRD(from input: String) async throws -> PRDocument {
        // Detect mockups in raw input
        let detection = mockupDetector.detectMockups(from: input)

        if detection.hasMockups {
            // Normalize mockup paths
            let mockupPaths = await mockupDetector.normalizeMockupPaths(detection.mockupSources)
            let structuredInput = PRDInput(
                text: detection.textContent,
                mockupPaths: mockupPaths,
                guidelines: detection.guidelines
            )
            let processedInput = try await inputProcessor.processStructuredInput(structuredInput)
            return try await orchestrator.orchestrateGeneration(
                from: processedInput,
                originalInput: input
            )
        } else {
            let processedInput = try await inputProcessor.processRawInput(input)
            return try await orchestrator.orchestrateGeneration(
                from: processedInput,
                originalInput: input
            )
        }
    }

    /// Generate PRD with structured input
    public func generatePRD(from input: PRDInput) async throws -> PRDocument {
        let processedInput = try await inputProcessor.processStructuredInput(input)
        let originalInput = input.text ?? "PRD Generation"
        return try await orchestrator.orchestrateGeneration(
            from: processedInput,
            originalInput: originalInput
        )
    }

    /// Generate PRD from raw input with automatic mockup detection
    public func generatePRDWithDetection(from rawInput: String) async throws -> PRDocument {
        return try await generatePRD(from: rawInput)
    }

    /// Generate PRD with optional export
    public func generatePRDWithExport(
        from input: String,
        exportTo path: String? = nil,
        format: PRDExporter.ExportFormat = .markdown
    ) async throws -> (document: PRDocument, exportPath: String?) {
        let document = try await generatePRD(from: input)
        let exportPath = try documentAssembler.exportIfRequested(
            document: document,
            exportPath: path,
            format: format
        )
        return (document, exportPath)
    }

    /// Generate PRD with structured input and optional export
    public func generatePRDWithExport(
        from input: PRDInput,
        exportTo path: String? = nil,
        format: PRDExporter.ExportFormat = .markdown
    ) async throws -> (document: PRDocument, exportPath: String?) {
        let document = try await generatePRD(from: input)
        let exportPath = try documentAssembler.exportIfRequested(
            document: document,
            exportPath: path,
            format: format
        )
        return (document, exportPath)
    }
}