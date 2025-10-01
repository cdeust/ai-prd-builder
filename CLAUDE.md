# CLAUDE.md — AI PRD Builder Swift SDK Engineering Memory

> Engineering memory for AI assistants to enforce **SOLID**, **Clean Architecture**, and proper project structure in the Swift iOS/macOS SDK.

---

## 0) How to use this with Claude

You are the repository's Engineering Memory. Enforce the rules below. When asked for code or reviews:
- Apply SOLID and Clean Architecture strictly
- Preserve the Swift package structure (Sources/domain/application/infrastructure)
- Refuse "quick hacks" that violate dependency rules; propose compliant alternatives
- Always output: (a) what changed, (b) why it follows the rules, (c) test impact
- If the user asks to break a rule, warn once and suggest a compliant path

---

## 1) SOLID Principles — Swift SDK Context

### S — Single Responsibility
**Principle:** A type/module should have exactly one reason to change.
**Heuristics:** Name explains purpose in ≤ 5 words; public API ≤ 7 methods; one primary actor.
**Smells to flag:** "Utils", "Manager", "Helper" grab-bags; mixed concerns (I/O + business); god objects.
**Swift-specific:** Avoid massive view models; use protocol extensions sparingly; separate concerns clearly.
**Refactor moves:** Extract protocol/struct; introduce façade; move I/O to infrastructure layer.

### O — Open/Closed
**Principle:** Open to extension, closed to modification.
**Heuristics:** New behavior via new types or protocol conformance, not by editing stable code.
**Smells:** Switch/case on type scattered around; editing a core type for every new variant.
**Swift-specific:** Leverage protocol extensions, generics, and associated types for extensibility.
**Refactor:** Strategy pattern, protocol-oriented programming, dependency injection.

### L — Liskov Substitution
**Principle:** Protocol conformances must be fully substitutable.
**Heuristics:** No strengthened preconditions or weakened postconditions; no `fatalError()` in implementations.
**Smells:** Protocol methods throwing `fatalError()`; type-checking with `is` or `as?` before use.
**Swift-specific:** Avoid force-unwrapping; use optional protocol requirements carefully.
**Refactor:** Prefer composition; use phantom types; split protocols.

### I — Interface Segregation
**Principle:** Many focused protocols > one fat protocol.
**Heuristics:** Clients depend only on methods they use; keep protocol requirements cohesive.
**Smells:** Protocol with 10+ requirements; conformers providing no-op implementations.
**Swift-specific:** Use protocol composition (`protocol Combined: A, B`); leverage default implementations wisely.
**Refactor:** Split protocols; create role-based protocols; use protocol inheritance.

### D — Dependency Inversion
**Principle:** High-level policy depends on abstractions, not concretes.
**Heuristics:** Domain defines protocols; infrastructure implements them.
**Smells:** Domain importing Foundation networking; business logic importing UIKit/AppKit.
**Swift-specific:** Define protocols in domain module; inject implementations via initializers.
**Refactor:** Create protocols in domain; implement in infrastructure; inject at composition root.

---

## 2) Clean Architecture — Swift Package Structure

### Current Architecture Layers

```
swift/
├─ Sources/
│  ├─ AIPRDBuilder/               # Main SDK module (public API)
│  │  ├─ Domain/                  # Pure business rules
│  │  │  ├─ Entities/            # Core business objects
│  │  │  ├─ ValueObjects/        # Immutable value types
│  │  │  ├─ Protocols/           # Domain protocols (repositories, services)
│  │  │  └─ Errors/              # Domain errors
│  │  ├─ Application/            # Use cases and app services
│  │  │  ├─ UseCases/            # Business workflows
│  │  │  ├─ Services/            # Application orchestration
│  │  │  └─ DTOs/                # Data transfer objects
│  │  ├─ Infrastructure/         # External implementations
│  │  │  ├─ Network/             # HTTP clients, API adapters
│  │  │  ├─ Persistence/         # CoreData, UserDefaults, Keychain
│  │  │  └─ Services/            # Third-party service wrappers
│  │  └─ Presentation/           # UI-related (if SDK includes UI)
│  │     ├─ ViewModels/          # Presentation logic
│  │     └─ Views/               # SwiftUI/UIKit views
│  └─ AIPRDBuilderTests/
├─ Package.swift
└─ README.md
```

### Dependency Rules

**Golden Rule:** Source code dependencies point **inward**. Data flows both ways via **protocols** and **DTOs**.

1. **Domain** depends on **nothing** (pure Swift, Foundation for basic types only)
2. **Application** depends only on **Domain**
3. **Infrastructure** depends on **Domain** and **Application** (implements protocols)
4. **Presentation** depends on **Application** (uses use cases)
5. **Main SDK module** exposes public API and wires dependencies

### Protocols & Implementations Naming

- **Protocols (Domain/Protocols/):** `PRDRepositoryProtocol`, `AIProviderProtocol`, `StorageProtocol`
- **Implementations (Infrastructure/):** `HTTPPRDRepository`, `OpenAIProvider`, `KeychainStorage`

### DTOs & Mappers

- Use Codable structs for API DTOs
- Map at boundaries: API↔DTO (infrastructure), DTO↔Entity (application)
- Keep domain entities framework-agnostic (no URLSession, Combine types in domain)

### Testing Strategy

- **Unit** (70–80%): Domain entities & use cases with protocol mocks
- **Contract** (10–15%): Verify infrastructure implementations against protocols
- **Integration** (10–15%): Test network/storage adapters with real or stubbed services
- **E2E** (thin): Critical SDK workflows via XCTest

### Review Checklist (must pass)

- [ ] Domain contains only Foundation basic types (String, Int, Date, etc.)
- [ ] No URLSession, Combine, CoreData in Domain layer
- [ ] Use cases depend only on domain protocols
- [ ] Infrastructure implements domain protocols
- [ ] Public SDK API is well-documented with DocC
- [ ] Tests follow pyramid; no network calls in unit tests

---

## 3) Swift SDK Best Practices

### Public API Design

**❌ Bad:** Exposing implementation details
```swift
public class PRDClient {
    public let httpClient: URLSession  // ❌ Leaking infrastructure
    public var apiKey: String          // ❌ Mutable state

    public func generate(config: [String: Any]) async throws -> [String: Any] {
        // ❌ Untyped dictionaries
    }
}
```

**✅ Good:** Clean, protocol-based API
```swift
public protocol PRDClientProtocol {
    func generate(config: PRDConfiguration) async throws -> PRDDocument
    func fetchStatus(requestId: UUID) async throws -> GenerationStatus
}

public final class PRDClient: PRDClientProtocol {
    private let repository: PRDRepositoryProtocol

    public init(apiKey: String, baseURL: URL) {
        // Wire dependencies internally
        let httpClient = HTTPPRDRepository(apiKey: apiKey, baseURL: baseURL)
        self.repository = httpClient
    }

    public func generate(config: PRDConfiguration) async throws -> PRDDocument {
        let useCase = GeneratePRDUseCase(repository: repository)
        return try await useCase.execute(config)
    }
}
```

### Dependency Injection

```swift
// Domain defines protocol
public protocol PRDRepositoryProtocol {
    func create(_ config: PRDConfiguration) async throws -> PRDDocument
    func fetch(id: UUID) async throws -> PRDDocument?
}

// Infrastructure implements
final class HTTPPRDRepository: PRDRepositoryProtocol {
    private let httpClient: URLSession
    private let apiKey: String

    init(httpClient: URLSession = .shared, apiKey: String) {
        self.httpClient = httpClient
        self.apiKey = apiKey
    }

    func create(_ config: PRDConfiguration) async throws -> PRDDocument {
        // Network implementation
    }
}

// Use case consumes protocol
public struct GeneratePRDUseCase {
    private let repository: PRDRepositoryProtocol

    public init(repository: PRDRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ config: PRDConfiguration) async throws -> PRDDocument {
        // Business logic
        return try await repository.create(config)
    }
}
```

### Error Handling

```swift
// Domain error
public enum PRDError: Error {
    case invalidConfiguration(String)
    case generationFailed(reason: String)
    case networkError(underlying: Error)
    case unauthorized
}

// Infrastructure maps external errors
extension HTTPPRDRepository {
    private func mapError(_ error: Error) -> PRDError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .networkError(underlying: error)
            default:
                return .networkError(underlying: error)
            }
        }
        return .generationFailed(reason: error.localizedDescription)
    }
}
```

---

## 4) Swift SDK-Specific Patterns

### Async/Await Over Combine

```swift
// ✅ Good: Modern async/await
public func generate(config: PRDConfiguration) async throws -> PRDDocument {
    try await repository.create(config)
}

// ❌ Avoid in new code: Combine publishers
public func generate(config: PRDConfiguration) -> AnyPublisher<PRDDocument, Error> {
    // Prefer async/await for simpler APIs
}
```

### Value Types for Entities

```swift
// ✅ Good: Immutable value types
public struct PRDConfiguration {
    public let projectName: String
    public let requirements: [String]
    public let provider: AIProvider
    public let mockups: [Mockup]

    public init(projectName: String, requirements: [String], provider: AIProvider, mockups: [Mockup]) {
        self.projectName = projectName
        self.requirements = requirements
        self.provider = provider
        self.mockups = mockups
    }
}

// ❌ Avoid: Mutable classes
public class PRDConfiguration {
    public var projectName: String
    public var requirements: [String]
    // ...
}
```

### Protocol-Oriented Mocking

```swift
// Easy to mock in tests
final class MockPRDRepository: PRDRepositoryProtocol {
    var createCallCount = 0
    var mockDocument: PRDDocument?

    func create(_ config: PRDConfiguration) async throws -> PRDDocument {
        createCallCount += 1
        if let doc = mockDocument {
            return doc
        }
        throw PRDError.generationFailed(reason: "Mock not configured")
    }
}

// Test
func testGenerateUseCase() async throws {
    let mockRepo = MockPRDRepository()
    mockRepo.mockDocument = PRDDocument(/* ... */)

    let useCase = GeneratePRDUseCase(repository: mockRepo)
    let result = try await useCase.execute(/* config */)

    XCTAssertEqual(mockRepo.createCallCount, 1)
}
```

---

## 5) Thinking Modes

### Core Thinking Flags

- **--think**: Multi-file analysis with context awareness (4K tokens)
  - Activates deeper analysis across multiple files
  - Considers interdependencies and broader context
  - Ideal for feature implementation and moderate complexity tasks

- **--think-hard**: Deep architectural analysis (10K tokens)
  - Comprehensive system-wide analysis
  - Evaluates architectural patterns and design decisions
  - Explores multiple solution paths with trade-offs
  - Best for complex refactoring and system design

- **--ultrathink**: Critical system redesign (32K tokens)
  - Maximum depth analysis for critical decisions
  - Complete architectural exploration
  - Reserved for major system changes and critical problem-solving

### Auto-Activation Triggers

Automatically activate thinking modes when detecting:
- Multi-file dependencies → --think
- Architectural decisions → --think-hard
- System-wide changes → --ultrathink
- Complex async patterns → --think-hard
- Security analysis → --ultrathink
- Performance optimization → --think-hard

### Integration Patterns
- **--think + --introspect**: Transparent multi-file reasoning
- **--think-hard + --introspect**: Visible architectural decision-making
- **--ultrathink + --introspect**: Complete cognitive transparency
- **--think + sequential**: Step-by-step multi-file analysis
- **--think-hard + sequential**: Progressive deep analysis
- **--ultrathink + sequential**: Exhaustive systematic exploration

### Progressive Escalation
1. Start with base analysis
2. If complexity detected → auto-suggest --think
3. If architectural impact → auto-suggest --think-hard
4. If critical/security → auto-suggest --ultrathink

### Token Economics
- Default mode: Minimal tokens, direct solutions
- --think: 4K token budget for broader context
- --think-hard: 10K token budget for deep analysis
- --ultrathink: 32K token budget for comprehensive exploration

### Usage Examples
- Bug fix in single file: No flag needed
- Feature touching 3+ files: Use --think
- Refactoring core module: Use --think-hard
- Redesigning authentication: Use --ultrathink
- Security audit: Use --ultrathink
- Performance optimization: Use --think-hard

### Cognitive Scaling Rules
1. Match thinking depth to problem complexity
2. Prefer minimal effective depth (token economy)
3. Escalate when initial analysis reveals complexity
4. Document reasoning for depth selection
5. Combine with --introspect for transparency when needed

---

## 6) Quick Prompts

- "Review this diff against Clean Architecture; list dependency violations"
- "Refactor this type to follow protocol-oriented design"
- "Extract this network logic to infrastructure layer"
- "Create a mock implementation of this protocol for testing"
- "Document this public API with DocC comments"

---

## 7) Opinionated Stances

- **Do not** expose URLSession, Combine, or CoreData in public API
- **Prefer value types** (struct) for entities and DTOs
- **Keep SDK surface area small**; expose only what clients need
- **No "god" protocols or managers**
- **Async operations return Result or async throws**; be consistent
- **Use @available** annotations to manage API evolution

---

## 8) Package.swift Configuration

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIPRDBuilder",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AIPRDBuilder",
            targets: ["AIPRDBuilder"]
        )
    ],
    dependencies: [
        // Keep external dependencies minimal
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "AIPRDBuilder",
            dependencies: [],
            path: "Sources/AIPRDBuilder"
        ),
        .testTarget(
            name: "AIPRDBuilderTests",
            dependencies: ["AIPRDBuilder"],
            path: "Tests/AIPRDBuilderTests"
        )
    ]
)
```

---

> If any code conflicts with this file, prefer **CLAUDE.md** and open an ADR to explain exceptions.
