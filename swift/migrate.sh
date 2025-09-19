#!/bin/bash

# Migration Script for AI PRD Builder Refactoring
# This script helps migrate files from the old structure to the new modular structure

set -e

echo "🔄 Starting migration to refactored architecture..."

# Function to copy and transform files
migrate_module() {
    local source_dir=$1
    local target_dir=$2
    local description=$3

    echo "📦 Migrating $description..."

    if [ -d "$source_dir" ]; then
        mkdir -p "$target_dir"
        # Copy Swift files, excluding build artifacts
        find "$source_dir" -name "*.swift" -type f | while read -r file; do
            relative_path=${file#$source_dir/}
            target_file="$target_dir/$relative_path"
            target_file_dir=$(dirname "$target_file")
            mkdir -p "$target_file_dir"
            cp "$file" "$target_file"
        done
        echo "   ✅ Migrated $description"
    else
        echo "   ⚠️  Source not found: $source_dir"
    fi
}

# Base directories
OLD_BASE="../swift/Sources"
NEW_BASE="./Sources"

# Migrate AIProviders -> Split into Core and Implementations
echo "📦 Splitting AIProviders..."
mkdir -p "$NEW_BASE/AIProvidersCore"
mkdir -p "$NEW_BASE/AIProviderImplementations"

# Copy protocol files to Core
if [ -f "$OLD_BASE/AIProviders/AIProvider.swift" ]; then
    cp "$OLD_BASE/AIProviders/AIProvider.swift" "$NEW_BASE/AIProvidersCore/"
fi

# Copy implementations
for provider in Anthropic OpenAI Gemini Apple Mock; do
    if [ -f "$OLD_BASE/AIProviders/${provider}Provider.swift" ]; then
        cp "$OLD_BASE/AIProviders/${provider}Provider.swift" "$NEW_BASE/AIProviderImplementations/"
    fi
done

# Extract TestGeneration from AIBridge
echo "📦 Extracting TestGeneration module..."
mkdir -p "$NEW_BASE/TestGeneration"
for file in TestData TestDataConstants TestGenerator; do
    if [ -f "$OLD_BASE/AIBridge/${file}.swift" ]; then
        cp "$OLD_BASE/AIBridge/${file}.swift" "$NEW_BASE/TestGeneration/"
    fi
done

# Extract PRDGenerator from AppleIntelligenceOrchestrator
echo "📦 Extracting PRDGenerator module..."
mkdir -p "$NEW_BASE/PRDGenerator"
for file in PRDGenerator PRDConstants PRDPhases; do
    if [ -f "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" ]; then
        cp "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" "$NEW_BASE/PRDGenerator/"
    fi
done

# Extract OpenAPIGenerator
echo "📦 Extracting OpenAPIGenerator module..."
mkdir -p "$NEW_BASE/OpenAPIGenerator"
for file in OpenAPIGenerator OpenAPIASTTypes OpenAPIValidator; do
    if [ -f "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" ]; then
        cp "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" "$NEW_BASE/OpenAPIGenerator/"
    fi
done

# Extract ValidationEngine
echo "📦 Extracting ValidationEngine module..."
mkdir -p "$NEW_BASE/ValidationEngine"
for file in ValidationConstraint Validator ValidationResult; do
    if [ -f "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" ]; then
        cp "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" "$NEW_BASE/ValidationEngine/"
    fi
done

# Migrate ThinkingFramework -> ThinkingCore (without AIBridge dependencies)
migrate_module "$OLD_BASE/ThinkingFramework" "$NEW_BASE/ThinkingCore" "ThinkingCore"

# Migrate ImplementationGenius -> ImplementationAnalysis
migrate_module "$OLD_BASE/ImplementationGenius" "$NEW_BASE/ImplementationAnalysis" "ImplementationAnalysis"

# Extract CLI from AppleIntelligenceOrchestrator
echo "📦 Extracting CLI module..."
mkdir -p "$NEW_BASE/CLI"
for file in main AppleIntelligenceOrchestrator CommandParser InteractiveMode; do
    if [ -f "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" ]; then
        cp "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" "$NEW_BASE/CLI/"
    fi
done

# Copy remaining AIBridge files to Orchestration
echo "📦 Creating Orchestration module..."
mkdir -p "$NEW_BASE/Orchestration"
find "$OLD_BASE/AIBridge" -name "*.swift" -type f | while read -r file; do
    filename=$(basename "$file")
    # Skip test-related files (already moved)
    if [[ ! "$filename" =~ Test ]]; then
        cp "$file" "$NEW_BASE/Orchestration/"
    fi
done

# Create SessionManagement
echo "📦 Creating SessionManagement module..."
mkdir -p "$NEW_BASE/SessionManagement"
for file in SessionManager ChatSession; do
    if [ -f "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" ]; then
        cp "$OLD_BASE/AppleIntelligenceOrchestrator/${file}.swift" "$NEW_BASE/SessionManagement/"
    fi
done

# Create test structure
echo "🧪 Setting up test infrastructure..."
mkdir -p Tests/CommonModelsTests
mkdir -p Tests/OrchestrationTests
mkdir -p Tests/PRDGeneratorTests

# Generate initial test files
cat > Tests/CommonModelsTests/ChatMessageTests.swift << 'EOF'
import XCTest
@testable import CommonModels

final class ChatMessageTests: XCTestCase {
    func testChatMessageCreation() {
        let message = ChatMessage(role: .user, content: "Test message")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Test message")
    }

    func testChatMessageEquality() {
        let message1 = ChatMessage(role: .assistant, content: "Response")
        let message2 = ChatMessage(role: .assistant, content: "Response")
        XCTAssertEqual(message1, message2)
    }
}
EOF

echo "✅ Migration script created!"
echo ""
echo "📋 Next Steps:"
echo "1. Review the migrated files"
echo "2. Update import statements to use new module names"
echo "3. Run 'swift build' to verify compilation"
echo "4. Run tests with 'swift test'"
echo ""
echo "🔄 To rollback: git checkout main"