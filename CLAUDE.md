# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Primary Build Commands
```bash
# Build the Swift package (debug mode)
cd swift && swift build

# Build for release
cd swift && swift build -c release

# Complete build with Metal library setup
cd swift && ./build.sh

# Run the application
swift run ai-orchestrator interactive
```

### Testing
```bash
# Run all tests
cd swift && swift test

# Run specific test
cd swift && swift test --filter PRDGeneratorTests

# Run tests with code coverage
cd swift && swift test --enable-code-coverage
```

### Code Quality
```bash
# Run SwiftLint (if installed)
swiftlint
```

## Architecture Overview

The project is a Swift-based AI orchestration system for generating Product Requirements Documents (PRDs) using Apple's Foundation Models, MLX framework, and external AI providers.

### Core Components

1. **AIBridge** (`swift/Sources/AIBridge/`)
   - Central orchestration layer managing AI provider selection and routing
   - Integrates with MLX framework for on-device models
   - Handles provider routing based on privacy settings

2. **AIProviders** (`swift/Sources/AIProviders/`)
   - Provider abstraction layer for multiple AI services
   - Integrates Apple Foundation Models, Anthropic, OpenAI, and Gemini
   - Privacy-first architecture: Apple models → Private Cloud → External APIs

3. **AppleIntelligenceOrchestrator** (`swift/Sources/AppleIntelligenceOrchestrator/`)
   - Main CLI application entry point
   - Interactive PRD generation with 6-phase process
   - Session management and user interaction handling

4. **ThinkingFramework** (`swift/Sources/ThinkingFramework/`)
   - Advanced reasoning system with chain-of-thought processing
   - Decision trees and assumption tracking
   - Validation and pattern detection capabilities

5. **ImplementationGenius** (`swift/Sources/ImplementationGenius/`)
   - Code analysis and verification tools
   - Implementation validation against specifications

### Key Design Patterns

- **Privacy Levels**: Three-tier system (On-Device → Private Cloud → External)
- **Async/Await**: Modern Swift concurrency throughout
- **Protocol-Oriented**: Heavy use of protocols for flexibility
- **MLX Integration**: Leverages Apple's MLX framework for on-device inference

## PRD Generation Process

The PRD generation follows a 6-phase iterative process:
1. Initial structure and feature extraction
2. Feature enrichment with details
3. OpenAPI 3.1.0 specification generation
4. Apple ecosystem test specifications
5. Technical requirements definition
6. Deployment configuration

## Dependencies

- **MLX Swift** (0.18.0+): Core machine learning framework
- **MLX Swift Examples**: LLM support components
- **Apple Foundation Models**: Private on-device models (macOS 16+)
- **Metal Framework**: GPU acceleration support

## Platform Requirements

- macOS 16.0+ (required for Apple Foundation Models)
- Apple Silicon Mac (M1/M2/M3 or later)
- Xcode 16.0+
- Swift 5.9+

## Configuration

User configuration stored at `~/.ai-orchestrator/config.json` containing:
- API keys for external providers (Anthropic, OpenAI, Gemini)
- Privacy settings controlling external provider usage

## Development Guidelines

- Follow Swift API Design Guidelines
- Use explicit access control (public/private/internal)
- Implement proper error handling with throws
- Write tests for all new functionality
- Update documentation alongside code changes