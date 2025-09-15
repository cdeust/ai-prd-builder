# Contributing to AI PRD Builder

First off, thank you for considering contributing to AI PRD Builder! It's people like you that make this tool better for everyone in the Apple Developer Community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Process](#development-process)
- [Style Guidelines](#style-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

- **Be respectful**: Different viewpoints and experiences are valuable
- **Be constructive**: Focus on what is best for the community
- **Be inclusive**: Welcome newcomers and support each other
- **Be professional**: Harassment and inappropriate behavior are not tolerated

## Getting Started

### Prerequisites

- macOS 16.0+ with Apple Silicon (M1/M2/M3)
- Xcode 16.0+
- Swift 5.9+
- Git and GitHub account
- Familiarity with Swift and Apple development ecosystem

### Setting Up Your Development Environment

1. **Fork the Repository**
   ```bash
   # Click "Fork" on GitHub, then:
   git clone https://github.com/YOUR_USERNAME/ai-prd-builder.git
   cd ai-prd-builder
   ```

2. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/cdeust/ai-prd-builder.git
   ```

3. **Install Dependencies**
   ```bash
   cd swift
   swift build
   ```

4. **Run Tests**
   ```bash
   swift test
   ```

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **System information** (macOS version, Xcode version, etc.)
- **Relevant logs or error messages**

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When suggesting an enhancement:

- **Use a clear title**
- **Provide a detailed description** of the proposed functionality
- **Explain why** this enhancement would be useful
- **List any alternatives** you've considered

### 🔧 Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Simple issues for newcomers
- `help wanted` - Issues where we need community help
- `documentation` - Documentation improvements

### 📝 Pull Requests

1. **Small, focused PRs**: One feature or fix per PR
2. **Include tests**: All new code requires tests
3. **Update documentation**: Keep docs in sync with code
4. **Follow style guidelines**: Use SwiftLint

## Development Process

### Branch Naming Convention

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test improvements

### Workflow

1. **Create a branch** from `main`
2. **Make your changes** in logical commits
3. **Write/update tests** for your changes
4. **Run tests locally** to ensure nothing breaks
5. **Update documentation** if needed
6. **Submit a pull request** with clear description

## Style Guidelines

### Swift Code Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

```swift
// MARK: - Good Example
public struct PRDGenerator {
    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    public func generate(from input: String) async throws -> PRD {
        // Implementation
    }
}

// MARK: - Avoid
struct prd_generator {  // Wrong naming
    var Orchestrator: Orchestrator  // Wrong capitalization

    func Generate(input: String) -> PRD {  // Wrong naming, missing async/throws
        // Implementation
    }
}
```

### Key Principles

- **Clarity over brevity**: Clear names and explicit types when helpful
- **Constants in separate files**: Use dedicated Constants files
- **Error handling**: Always use proper error handling with throws
- **Async/await**: Use modern concurrency for async operations
- **Access control**: Be explicit with public/private/internal

### Documentation

- **Public APIs**: Must have documentation comments
- **Complex logic**: Include explanatory comments
- **TODOs**: Allowed but must include issue number

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **refactor**: Code refactoring
- **test**: Test additions or fixes
- **perf**: Performance improvements
- **chore**: Maintenance tasks

### Examples

```bash
# Good
git commit -m "feat: Add OpenAPI 3.1.0 support for PRD generation"
git commit -m "fix: Resolve context window overflow in Phase 2"
git commit -m "docs: Update installation requirements for macOS 16"

# Bad
git commit -m "updated stuff"
git commit -m "fix"
git commit -m "LOTS OF CHANGES!!!"
```

## Pull Request Process

### Before Submitting

1. **Update from upstream**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all tests**
   ```bash
   swift test
   ```

3. **Check code style**
   ```bash
   swiftlint
   ```

### PR Requirements

- **Title**: Clear and descriptive
- **Description**: Use the PR template
- **Tests**: All tests must pass
- **Reviews**: Requires at least one approval
- **Conflicts**: Must be resolved before merge

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] New tests added
- [ ] Existing tests updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No warnings generated
```

## Community

### Getting Help

- **GitHub Issues**: Technical problems and bugs
- **GitHub Discussions**: General questions and ideas
- **Swift Forums**: Broader Swift ecosystem questions

### Recognition

Contributors are recognized in:
- The README.md acknowledgments
- Release notes
- Annual contributor spotlight (for significant contributions)

## 🙏 Thank You!

Your contributions make AI PRD Builder better for the entire Apple Developer Community. Every contribution, no matter how small, is valued and appreciated.

---

**Questions?** Feel free to open an issue or start a discussion. We're here to help!