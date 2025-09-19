# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the ai-prd-builder repository. It sets expectations, architectural context, coding standards, testing strategy, and workflow rules to ensure clean, maintainable, and test-driven development.

---

## Build Commands

### Primary Build Commands
```bash
cd swift && swift build # Debug build
cd swift && swift build -c release # Release build
cd swift && ./build.sh # Full build including Metal setup
swift run ai-orchestrator interactive # Run interactive CLI
```

### Testing
```bash
# Run all tests
cd swift && swift test # Run all tests
cd swift && swift test --filter PRDGeneratorTests # Run specific tests
cd swift && swift test --enable-code-coverage # Run with coverage
```

### Code Quality
```bash
swiftlint # Run SwiftLint if available
```

---

## Architecture Overview

The project is a Swift AI orchestration system focused on generating PRDs using Apple Foundation Models, MLX, and external AI providers.

### Core Modules & Responsibility

- **AIBridge**: Orchestrates AI providers, manages routing and privacy (on-device → private cloud → external APIs)
- **AIProviders**: Protocol-based abstraction to integrate Apple, Anthropic, OpenAI, Gemini providers
- **AppleIntelligenceOrchestrator**: CLI entry point, manages chat sessions and PRD generation phases
- **ThinkingFramework**: Implements advanced reasoning, chain-of-thought, validation
- **ImplementationGenius**: Code analysis and implementation verification

### Design Patterns

- Clean Architecture: separation of concerns by layers and modules
- SOLID principles applied via protocol orientation and dependency injection
- Swift concurrency with async/await
- Privacy-first tiered AI provider fallback

---

## Coding Standards & Principles

- Follow Swift API Design Guidelines  
- Use explicit access controls (`public`, `private`, `internal`)  
- Favor protocol-oriented programming, avoid tight coupling  
- Enforce Single Responsibility Principle on classes and methods  
- Write concise, expressive, and well-documented code  
- Handle errors with Swift’s `throws` and proper error types  
- Avoid global mutable state; prefer immutability and dependency injection

---

## Testing Strategy & TDD Process

- Every new feature or bug fix must begin with unit tests (XCTest)  
- Tests must cover nominal flows, edge cases, and error conditions  
- Integration tests for AI provider interoperability and orchestration flows  
- Maintain incremental and iterative testing aligned with changes  
- Use coverage tools to identify untested paths and prioritize tests accordingly  
- CI pipelines must run tests and lint checks before merging  
- Commit and review code/tests in atomic increments

---

## PRD Generation Process (High-Level)

Follow the 6-phase iterative process during PRD creation:  
1. Initial PRD structure and feature extraction  
2. Enrich PRD with details and clarifications  
3. Generate OpenAPI 3.1.0 specifications  
4. Create test specifications for Apple ecosystem  
5. Define technical requirements according to Apple guidelines  
6. Generate deployment configurations (TestFlight, App Store)

---

## Agent Interaction Guidelines

- Always operate on minimal code units (methods, small classes) for refactoring or feature additions  
- Modifications must respect current architecture and SOLID principles  
- Avoid wide-scope file rewrites; prefer iterative incremental improvements  
- Auto-generate or enhance tests alongside functional changes  
- Use prompts specifying exact scope, e.g.:  
  > "Modify only the `generateOpenAPISpec()` method in `PRDGenerator.swift`. Do not change other parts of the file."  
- When suggesting abstractions or refactorings, explain reasoning clearly  
- Validate all code changes with passing tests and review edge cases

---

## Privacy & Configuration

- Respect privacy-first architecture, only use external AI providers when configured and authorized  
- Store API keys and preferences in `~/.ai-orchestrator/config.json`  
- Default to Apple Foundation Models on-device for maximum privacy and speed  

---

## Development Workflow

- Use feature branches for isolated work and PR reviews  
- Write clear commit messages describing scope and intent  
- Continuously rebase and sync with main branch to minimize conflicts  
- Run build, lint, and tests locally before pushing  
- Use CLI interactive mode for iterative PRD creation and debugging

---

## Relevant Documentation

- Apple Foundation Models and MLX framework documentation  
- Swift concurrency and protocol-oriented programming guides  
- Project README and module-level documentation under `swift/Sources`

---

## Summary

This CLAUDE.md frames the expected quality, architecture, and workflow of the ai-prd-builder project while enabling smooth AI-powered development with Claude Code. It enforces modular, test-driven, clean architecture principles aligned with Swift best practices.

---

*Built for the ai-prd-builder project using Apple Intelligence and Foundation Models.*
