#!/bin/bash

# Fix ChainOfThought.swift
cat > /tmp/fix1.swift << 'EOF'
    private func generateStructuredReasoning(
        prompt: String
    ) async throws -> String {
        // Don't over-instruct the model (2025 finding)
        // Let it naturally generate reasoning without explicit "think step by step" instructions
        let messages = [ChatMessage(role: .user, content: prompt)]
        let result = await provider.sendMessages(messages)

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
EOF

# Fix another method in ChainOfThought.swift
cat > /tmp/fix2.swift << 'EOF'
    private func extractAssumptions(from text: String) async -> [Assumption] {
        let prompt = String(format: ChainOfThoughtConstants.extractAssumptionsTemplate, text)

        do {
            let messages = [ChatMessage(role: .user, content: prompt)]
            let result = await provider.sendMessages(messages)

            switch result {
            case .success(let response):
                // Parse response and create assumptions
                return ChainOfThoughtParser.parseAssumptions(from: response, context: text)
            case .failure:
                return []
            }
        } catch {
            return []
        }
    }
EOF

echo "Fixes created. Apply manually to the files."