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
- **Comprehensive PRD Generation**: Creates complete specifications including:
  - Feature specifications with user stories
  - OpenAPI 3.1.0 contracts
  - Apple ecosystem test specifications
  - Technical requirements aligned with Apple Human Interface Guidelines
  - Deployment configurations for TestFlight and App Store
- **Thinking Modes**: Advanced reasoning capabilities for thorough analysis
- **YAML Output**: Clean, structured output ready for implementation

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

1. **Phase 1**: Initial structure and feature extraction
2. **Phase 2**: Feature enrichment with details
3. **Phase 3**: OpenAPI specification generation
4. **Phase 4**: Test specifications for Apple ecosystem
5. **Phase 5**: Technical requirements definition
6. **Phase 6**: Deployment configuration

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
│   │   ├── AIBridge/              # Core orchestration logic
│   │   ├── AIProviders/           # Provider integrations
│   │   ├── AppleIntelligenceOrchestrator/  # Main application
│   │   ├── ImplementationGenius/  # Code analysis tools
│   │   └── ThinkingFramework/     # Reasoning systems
│   └── Tests/
└── Documentation/
```

### Key Components

- **Orchestrator**: Manages AI provider selection and routing
- **PRDGenerator**: Handles iterative PRD creation
- **ThinkingModeManager**: Implements various reasoning strategies
- **ProviderRouter**: Routes requests based on privacy settings

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

1. Implement `AIProvider` protocol
2. Add to `ProviderFactory`
3. Update configuration handling
4. Add tests

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
- Technical specifications (OpenAPI, test code) with appropriate tools
- Business logic against actual requirements
- Performance targets against realistic benchmarks
- Compliance with organizational standards

### Privacy Considerations

- Apple Foundation Models process data on-device
- Private Cloud Compute ensures verifiable privacy
- External providers are only used with explicit permission
- No data is stored or logged without user consent

---

**Built with ❤️ for the Apple Developer Community**