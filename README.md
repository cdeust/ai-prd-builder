# AI PRD Builder 🚀

An intelligent Product Requirements Document (PRD) generator that leverages Apple Intelligence and Foundation Models to create comprehensive, implementation-ready specifications from conversational interactions.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017%20|%20macOS%2016-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Overview

AI PRD Builder transforms conversational descriptions into structured, detailed Product Requirements Documents that any GenAI model can use for implementation. It prioritizes privacy by using Apple's on-device Foundation Models and Private Cloud Compute before falling back to external providers.

### Key Features

- **Privacy-First Architecture**: Apple Foundation Models → Private Cloud Compute → External APIs (only when authorized)
- **Multi-Model Integration**: Seamlessly works with Apple Intelligence, Anthropic, OpenAI, and Gemini
- **Intelligent Clarification System**: Proactively identifies and collects missing requirements before generation
- **Confidence-Based Generation**: Evaluates input completeness and adjusts generation strategy accordingly
- **Comprehensive PRD Generation**: Creates complete specifications including:
  - Product overview and target users
  - User stories with acceptance criteria
  - Feature specifications with prioritization
  - API endpoints overview and usage patterns
  - Test specifications for the Apple ecosystem
  - Performance, security, and compatibility constraints
  - Validation criteria and technical roadmap
- **Advanced Reasoning**: Multi-pass generation with assumption validation
- **Smart Deduplication**: Prevents redundant questions using Levenshtein distance and Jaccard similarity

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Architecture](#-architecture)
- [Contributing](#-contributing)
- [Development](#-development)
- [Testing](#-testing)
- [License](#-license)

## 🛠 Installation

### Prerequisites

- **macOS 16.0+** (Required for Apple Foundation Models)
- **Xcode 16.0+** (Required for latest Swift features)
- **Swift 5.9+**
- **Apple Silicon Mac** (Required - M1/M2/M3 or later)

### Clone the Repository

```bash
git clone https://github.com/cdeust/ai-prd-builder.git
cd ai-prd-builder
```

### Build from Source

```bash
cd swift
swift build -c release
```

### Install Binary

```bash
# Copy to local bin
cp .build/release/AppleIntelligenceOrchestrator /usr/local/bin/ai-orchestrator

# Make executable
chmod +x /usr/local/bin/ai-orchestrator
```

### Environment Setup

Create a configuration file at `~/.ai-orchestrator/config.json`:

```json
{
  "providers": {
    "anthropic": {
      "apiKey": "YOUR_ANTHROPIC_API_KEY"
    },
    "openai": {
      "apiKey": "YOUR_OPENAI_API_KEY"
    },
    "gemini": {
      "apiKey": "YOUR_GEMINI_API_KEY"
    }
  },
  "privacy": {
    "allowExternal": false
  }
}
```

## 🚀 Quick Start

### Basic Usage

```bash
# Start interactive mode
ai-orchestrator

# Generate a PRD
> prd
Describe what you want to build:
> I need a task management app with real-time collaboration...

# Chat with AI
> chat
Enter your message:
> How should I structure the authentication flow?
```

### Command Line Options

```bash
# Allow external providers (when needed for complex tasks)
ai-orchestrator --allow-external

# Use specific provider
ai-orchestrator --provider anthropic

# Generate PRD directly
ai-orchestrator prd --input "Your product description"
```

## 💡 Usage

### Available Commands

| Command | Description |
|---------|-------------|
| `chat` | Start a conversational AI session |
| `prd` | Generate a Product Requirements Document |
| `session` | Manage chat sessions |
| `providers` | List available AI providers |
| `help` | Show help information |
| `exit` | Quit the application |

### PRD Generation Process

#### Pre-Generation Analysis
1. **Requirements Analysis**: Evaluates input completeness and identifies gaps
2. **Technical Stack Discovery**: Analyzes technical requirements and platform needs
3. **Clarification Collection**: Intelligently collects missing information from users
4. **Confidence Evaluation**: Determines generation strategy based on confidence levels

#### Generation Phases
1. **Product Overview**: Goals, target users, and context
2. **User Stories**: Detailed stories with acceptance criteria
3. **Features**: Comprehensive feature list with prioritization
4. **API Endpoints**: Overview of required endpoints and usage patterns
5. **Test Specifications**: Test cases aligned with implementation
6. **Constraints**: Performance, security, and compatibility requirements
7. **Validation Criteria**: Success metrics and acceptance conditions
8. **Technical Roadmap**: Implementation timeline and CI/CD strategy

#### Confidence Thresholds
- **<40%**: Too vague - requires essential information collection
- **40-70%**: Needs clarification for optimal results
- **70-85%**: Good confidence, optional clarifications
- **>85%**: High confidence, proceed with generation

### Privacy Modes

The tool operates in three privacy levels:

1. **On-Device Only**: Uses Apple Foundation Models exclusively
2. **Private Cloud**: Adds Apple Private Cloud Compute for complex tasks
3. **Extended** (with `--allow-external`): Enables external providers for maximum capability

## 🏗 Architecture

```
ai-prd-builder/
├── swift/
│   ├── Sources/
│   │   ├── Orchestration/         # Core orchestration and routing
│   │   ├── AIProvidersCore/       # Provider protocols and abstractions
│   │   ├── AIProviderImplementations/ # Concrete provider implementations
│   │   ├── PRDGenerator/          # PRD generation engine
│   │   │   └── Components/        # Modular generation components
│   │   ├── SessionManagement/     # Session and state management
│   │   ├── CLI/                   # Command-line interface
│   │   ├── DomainCore/           # Core domain models
│   │   ├── CommonModels/         # Shared data structures
│   │   └── ThinkingCore/         # Reasoning and analysis
│   └── Tests/
└── Documentation/
```

### Key Components

#### Core Systems
- **Orchestrator**: Manages AI provider selection with privacy-first routing
- **PRDGenerator**: Coordinates the complete PRD generation pipeline
- **SessionManager**: Handles conversation sessions and state

#### PRD Generation Components
- **RequirementsAnalyzer**: Orchestrates pre-generation analysis and clarification
- **ConfidenceEvaluator**: Evaluates input quality and determines strategy
- **ClarificationCollector**: Manages user interaction and deduplication
- **AnalysisOrchestrator**: Coordinates AI-based requirement analysis
- **SectionGenerator**: Generates individual PRD sections
- **ValidationHandler**: Validates and improves generated content

#### Intelligence Features
- **Smart Deduplication**: Uses Levenshtein distance (70% threshold) and Jaccard similarity (60% threshold)
- **Confidence Filtering**: Filters assumptions and clarifications based on confidence levels
- **Parallel Analysis**: Concurrent requirements and stack analysis for performance

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Run tests**
   ```bash
   swift test
   ```
5. **Commit with descriptive message**
   ```bash
   git commit -m "Add amazing feature"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Write unit tests for new features
- Update documentation as needed

## 🔧 Development

### Project Structure

- **AIBridge**: Core orchestration and service management
- **AIProviders**: Integration with various AI providers
- **AppleIntelligenceOrchestrator**: CLI application and user interface
- **ImplementationGenius**: Code analysis and implementation verification
- **ThinkingFramework**: Advanced reasoning and decision-making

### Building for Development

```bash
# Debug build
swift build

# Run tests
swift test

# Generate Xcode project
swift package generate-xcodeproj
```

### Adding New Providers

1. Implement `AIProvider` protocol in `AIProviderImplementations/`
2. Add provider configuration to `Configuration` struct
3. Register in `Orchestrator` initialization
4. Add integration tests
5. Update documentation

### Extending the Clarification System

1. Add new question categories to `PRDConstants`
2. Extend `AnalysisOrchestrator` for domain-specific analysis
3. Update confidence thresholds if needed
4. Test deduplication with new question patterns

## 🧪 Testing

### Running Tests

```bash
# All tests
swift test

# Specific test
swift test --filter PRDGeneratorTests

# With coverage
swift test --enable-code-coverage
```

### Test Categories

- **Unit Tests**: Core logic and utilities
- **Integration Tests**: Provider integrations
- **Performance Tests**: Response time and memory usage

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple for Foundation Models and Private Cloud Compute
- The Swift community for excellent tools and libraries
- Contributors and users who help improve this tool

## 📮 Support

- **Issues**: [GitHub Issues](https://github.com/cdeust/ai-prd-builder/issues)
- **Discussions**: [GitHub Discussions](https://github.com/cdeust/ai-prd-builder/discussions)

## ⚠️ Important Notes

### AI-Generated Content

PRDs generated by this tool require human review and validation. Always verify:
- API endpoint definitions against implementation requirements
- Test specifications with your testing framework
- Business logic against actual requirements
- Performance targets against realistic benchmarks
- Compliance with organizational standards

### Privacy Considerations

- Apple Foundation Models process data on-device
- Private Cloud Compute ensures verifiable privacy
- External providers are only used with explicit permission
- No data is stored or logged without user consent

### Clarification System

The intelligent clarification system:
- **Never asks duplicate questions**: Uses advanced similarity algorithms
- **Respects confidence levels**: Only asks when truly needed
- **Prioritizes user experience**: Batches questions by category
- **Improves generation quality**: Better input leads to better PRDs

---

**Built with ❤️ for the Apple Developer Community**