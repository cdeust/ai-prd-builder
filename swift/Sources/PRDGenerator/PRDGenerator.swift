import Foundation
import CommonModels
import DomainCore

public final class PRDGenerator: PRDGeneratorProtocol {
    private let provider: AIProvider
    private let configuration: Configuration

    public init(provider: AIProvider, configuration: Configuration) {
        self.provider = provider
        self.configuration = configuration
    }

    public func generatePRD(from input: String) async throws -> PRDocument {
        var sections: [CommonModels.PRDSection] = []

        print("📝 Generating PRD in multiple passes to avoid context limits...")
        print("📊 Input length: \(input.count) characters")

        // Pass 1: Product Overview & Goals
        print("  1️⃣ Product Overview...")
        do {
            let overview = try await generateSection(input: input, prompt: PRDPrompts.overviewPrompt)
            sections.append(PRDSection(
                title: "Product Overview",
                content: overview
            ))
            print("     ✓ Overview generated")
        } catch {
            print("     ✗ Overview failed: \(error)")
            // Add fallback content
            sections.append(PRDSection(
                title: "Product Overview",
                content: "Error generating overview: \(error.localizedDescription)"
            ))
        }

        // Pass 2: User Stories
        print("  2️⃣ User Stories...")
        do {
            let userStories = try await generateSection(input: input, prompt: PRDPrompts.userStoriesPrompt)
            sections.append(PRDSection(
                title: "User Stories",
                content: userStories
            ))
            print("     ✓ User Stories generated")
        } catch {
            print("     ✗ User Stories failed: \(error)")
            sections.append(PRDSection(
                title: "User Stories",
                content: "Error generating user stories: \(error.localizedDescription)"
            ))
        }

        // Pass 3: Features List
        print("  3️⃣ Features List...")
        let features = try await generateSection(input: input, prompt: PRDPrompts.featuresPrompt)
        sections.append(PRDSection(
            title: "Features",
            content: features
        ))

        // Pass 4: OpenAPI Specification
        print("  4️⃣ API Specification...")
        let apiSpec = try await generateSection(input: input, prompt: PRDPrompts.apiSpecPrompt)
        sections.append(PRDSection(
            title: "OpenAPI 3.1.0 Specification",
            content: apiSpec
        ))

        // Pass 5: Test Specifications
        print("  5️⃣ Test Specifications...")
        let testSpec = try await generateSection(input: input, prompt: PRDPrompts.testSpecPrompt)
        sections.append(PRDSection(
            title: "Test Specifications",
            content: testSpec
        ))

        // Pass 6: Constraints
        print("  6️⃣ Constraints...")
        let constraints = try await generateSection(input: input, prompt: PRDPrompts.constraintsPrompt)
        sections.append(PRDSection(
            title: "Performance, Security & Compatibility Constraints",
            content: constraints
        ))

        // Pass 7: Validation Criteria
        print("  7️⃣ Validation Criteria...")
        let validation = try await generateSection(input: input, prompt: PRDPrompts.validationPrompt)
        sections.append(PRDSection(
            title: "Validation Criteria",
            content: validation
        ))

        // Pass 8: Technical Roadmap
        print("  8️⃣ Technical Roadmap...")
        let roadmap = try await generateSection(input: input, prompt: PRDPrompts.roadmapPrompt)
        sections.append(PRDSection(
            title: "Technical Roadmap & CI/CD",
            content: roadmap
        ))

        print("✅ PRD generation complete!")

        return PRDocument(
            title: formatTitle(input),
            sections: sections,
            metadata: [
                "generator": "PRDGenerator",
                "version": "4.0",
                "timestamp": Date().timeIntervalSince1970,
                "passes": 8,
                "approach": "Multi-pass generation"
            ]
        )
    }

    // MARK: - Helper Methods

    private func generateSection(input: String, prompt: String) async throws -> String {
        let formattedPrompt = prompt.replacingOccurrences(of: "%%@", with: input)

        // Log prompt size for debugging
        print("       Prompt size: \(formattedPrompt.count) chars")

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: formattedPrompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            print("       Response size: \(response.count) chars")
            return response
        case .failure(let error):
            print("       Error: \(error)")
            throw error
        }
    }

    private func formatTitle(_ input: String) -> String {
        // Extract first line or first 50 characters as title
        let firstLine = input.split(separator: "\n").first ?? ""
        let title = String(firstLine.prefix(50))
        return "\(title) - PRD"
    }
}

// MARK: - Supporting Types

public struct Feature {
    public let name: String
    public let description: String
    public let priority: Priority

    public enum Priority {
        case critical  // P0
        case high      // P1
        case medium    // P2
        case low       // P3
    }
}