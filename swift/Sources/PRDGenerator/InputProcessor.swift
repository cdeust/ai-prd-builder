import Foundation
import CommonModels
import DomainCore

/// Handles all input processing for PRD generation
public final class InputProcessor {
    private let mockupProcessor: MockupProcessor
    private let mockupDetector: MockupInputDetector

    public init(provider: AIProvider, configuration: Configuration) {
        self.mockupProcessor = MockupProcessor(provider: provider, configuration: configuration)
        self.mockupDetector = MockupInputDetector()
    }

    /// Process raw string input with automatic mockup detection
    public func processRawInput(_ input: String) async throws -> ProcessedInput {
        let detection = mockupDetector.detectMockups(from: input)

        if detection.hasMockups {
            let mockupPaths = await mockupDetector.normalizeMockupPaths(detection.mockupSources)
            return try await processStructuredInput(
                PRDGeneratorService.PRDInput(
                    text: detection.textContent,
                    mockupPaths: mockupPaths,
                    guidelines: detection.guidelines
                )
            )
        } else {
            return ProcessedInput(
                combinedContent: input,
                hasMockups: false,
                mockupCount: 0
            )
        }
    }

    /// Process structured PRDInput
    public func processStructuredInput(_ input: PRDGeneratorService.PRDInput) async throws -> ProcessedInput {
        var components: [String] = []

        // Add text description if provided
        if let text = input.text, !text.isEmpty {
            components.append(text)
        }

        // Process mockups if provided
        let mockupCount = input.mockupPaths.count
        if !input.mockupPaths.isEmpty {
            let mockupAnalysis = try await mockupProcessor.processMockups(
                paths: input.mockupPaths,
                guidelines: input.guidelines,
                context: input.text
            )
            components.append(mockupAnalysis)
        }

        // Add guidelines if provided separately
        if let guidelines = input.guidelines, !guidelines.isEmpty && input.mockupPaths.isEmpty {
            components.append(PRDContextConstants.DesignGuidelines.header + ": " + guidelines)
        }

        // Handle case where no input is provided
        if components.isEmpty {
            components.append("Generate a comprehensive PRD template with placeholder sections for a typical web application.")
        }

        return ProcessedInput(
            combinedContent: components.joined(separator: PRDDataConstants.Separators.sectionSeparator),
            hasMockups: !input.mockupPaths.isEmpty,
            mockupCount: mockupCount
        )
    }
}

/// Result of input processing
public struct ProcessedInput {
    public let combinedContent: String
    public let hasMockups: Bool
    public let mockupCount: Int
}