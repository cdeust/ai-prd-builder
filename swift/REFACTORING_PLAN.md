# Refactoring Plan - AI PRD Builder

## Overview
This refactoring addresses critical architectural issues identified:
- Circular dependencies between modules
- God module anti-patterns
- Missing test infrastructure
- Poor separation of concerns

## New Architecture

### Layer 1: Core Domain (No dependencies)
- `CommonModels/` - Shared data structures and protocols
- `DomainCore/` - Business entities and value objects

### Layer 2: Business Logic
- `ThinkingCore/` - Reasoning engine (extracted from ThinkingFramework)
- `PRDGenerator/` - PRD generation logic (extracted from AppleIntelligenceOrchestrator)
- `OpenAPIGenerator/` - OpenAPI spec generation (extracted)
- `TestGeneration/` - Test generation (extracted from AIBridge)
- `ValidationEngine/` - Validation logic (extracted)

### Layer 3: Infrastructure
- `AIProvidersCore/` - Provider protocols and abstractions
- `AIProviderImplementations/` - Concrete provider implementations
- `MLXIntegration/` - MLX framework integration
- `ImplementationAnalysis/` - Code analysis tools

### Layer 4: Application
- `Orchestration/` - Main orchestration logic (refined AIBridge)
- `SessionManagement/` - Chat and session handling

### Layer 5: Presentation
- `CLI/` - Command-line interface (extracted from AppleIntelligenceOrchestrator)
- `APIServer/` - Future REST API server

## Implementation Phases

### Phase 1: Immediate (Today)
1. Create CommonModels module with shared types
2. Extract TestGeneration from AIBridge
3. Fix circular dependency with protocol extraction

### Phase 2: Short-term (This Week)
1. Split AIProviders into Core and Implementations
2. Extract PRDGenerator from AppleIntelligenceOrchestrator
3. Create test infrastructure

### Phase 3: Medium-term (Next 2 Weeks)
1. Complete module separation
2. Implement comprehensive tests
3. Documentation generation

## Rollback Strategy
- All work in `refactor/modular-architecture-v2` branch
- Original code untouched in `swift/` directory
- Can switch back to main branch anytime
- Incremental migration possible

## Success Metrics
- Zero circular dependencies
- All modules < 500 lines per file
- 80% test coverage target
- Clean dependency graph
- Build time < 30 seconds
