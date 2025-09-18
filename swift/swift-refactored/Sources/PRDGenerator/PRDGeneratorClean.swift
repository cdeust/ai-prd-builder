import Foundation
import CommonModels
import DomainCore
import AIProvidersCore

public final class PRDGeneratorClean: PRDGeneratorProtocol {
    private let provider: AIProvider
    private let configuration: Configuration

    public init(provider: AIProvider, configuration: Configuration) {
        self.provider = provider
        self.configuration = configuration
    }

    public func generatePRD(from input: String) async throws -> PRDocument {
        var sections: [PRDSection] = []

        // Phase 1: Generate overview
        let overview = try await generateOverview(input: input)
        sections.append(PRDSection(
            title: "Product Overview",
            content: overview
        ))

        // Phase 2: Extract and enhance features
        let features = try await generateFeatures(input: input, context: overview)
        sections.append(PRDSection(
            title: "Core Features",
            content: "",
            subsections: features.map { feature in
                PRDSection(
                    title: feature.name,
                    content: feature.description
                )
            }
        ))

        // Phase 3: Generate user personas
        let personas = try await generateUserPersonas(input: input)
        sections.append(PRDSection(
            title: "Target Users & Personas",
            content: personas
        ))

        // Phase 4: Success metrics
        let metrics = try await generateSuccessMetrics(input: input, features: features)
        sections.append(PRDSection(
            title: "Success Metrics",
            content: metrics
        ))

        // Phase 5: Technical requirements
        let techReqs = try await generateTechnicalRequirements(input: input)
        sections.append(PRDSection(
            title: "Technical Requirements",
            content: techReqs
        ))

        return PRDocument(
            title: formatTitle(input),
            sections: sections,
            metadata: [
                "generator": "PRDGeneratorClean",
                "version": "2.0",
                "timestamp": Date().timeIntervalSince1970,
                "phases": 5
            ]
        )
    }

    // MARK: - Phase Generators

    private func generateOverview(input: String) async throws -> String {
        let prompt = """
        Generate a comprehensive product overview for: \(input)

        Include:
        - Product vision and goals
        - Key value propositions
        - Problem being solved
        - Target market

        Keep it concise (2-3 paragraphs).
        """

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    private func generateFeatures(input: String, context: String) async throws -> [Feature] {
        let prompt = """
        Based on this product: \(input)
        Context: \(context)

        Generate 5-8 core features with:
        - Feature name
        - Description
        - User value
        - Priority (P0-P3)

        Format as structured list.
        """

        let messages = [
            ChatMessage(role: .system, content: PRDPrompts.systemPrompt),
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return parseFeatures(from: response)
        case .failure(let error):
            throw error
        }
    }

    private func generateUserPersonas(input: String) async throws -> String {
        let prompt = """
        Create 3-5 detailed user personas for: \(input)

        Each persona should include:
        - Name and role
        - Goals and motivations
        - Pain points
        - How they would use the product
        """

        let messages = [
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    private func generateSuccessMetrics(input: String, features: [Feature]) async throws -> String {
        let featureList = features.map { $0.name }.joined(separator: ", ")
        let prompt = """
        Define 5-7 success metrics for: \(input)

        Core features: \(featureList)

        Include:
        - KPIs with specific targets
        - User engagement metrics
        - Business impact metrics
        - Technical performance metrics
        """

        let messages = [
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    private func generateTechnicalRequirements(input: String) async throws -> String {
        let prompt = """
        Define technical requirements for: \(input)

        Include:
        - Platform requirements (iOS, macOS, etc.)
        - Performance requirements
        - Security requirements
        - Integration requirements
        - Scalability considerations
        """

        let messages = [
            ChatMessage(role: .user, content: prompt)
        ]

        let result = await provider.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Helper Methods

    private func formatTitle(_ input: String) -> String {
        let words = input.split(separator: " ").prefix(5)
        let title = words.joined(separator: " ")
        return "\(title) - Product Requirements Document"
    }

    private func parseFeatures(from response: String) -> [Feature] {
        var features: [Feature] = []
        let lines = response.split(separator: "\n")

        var currentFeature: Feature?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") {
                if let feature = currentFeature {
                    features.append(feature)
                }
                let name = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                currentFeature = Feature(
                    name: String(name),
                    description: "",
                    priority: .medium
                )
            } else if let feature = currentFeature, !trimmed.isEmpty {
                currentFeature = Feature(
                    name: feature.name,
                    description: feature.description + " " + trimmed,
                    priority: feature.priority
                )
            }
        }

        if let feature = currentFeature {
            features.append(feature)
        }

        return features
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