# AI Provider API with MCP Support

REST API server that bridges AI providers (Anthropic, OpenAI) with MCP tools like Figma for enhanced PRD generation.

## Features

- Multiple AI provider support (Anthropic, OpenAI)
- MCP integration for external tools
- Figma MCP connector for design asset extraction
- PRD generation with design context
- Streaming chat support

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your API keys
```

3. Run development server:
```bash
npm run dev
```

## API Endpoints

### Health Check
```
GET /health
```

### Chat Completion
```
POST /chat
{
  "messages": [...],
  "provider": "anthropic" | "openai",
  "stream": true/false
}
```

### Generate PRD with Design Assets
```
POST /prd/generate
{
  "description": "Product description",
  "figmaUrl": "https://figma.com/file/...",
  "includeDesignAssets": true,
  "domain": "e-commerce"
}
```

### List Providers
```
GET /providers
```

## MCP Integration

The server can connect to MCP servers to enhance capabilities:

- **Figma MCP**: Extracts components, frames, and styles from Figma designs
- Extensible to other MCP tools (databases, APIs, etc.)

## Architecture

```
api-server/
├── src/
│   ├── providers/     # AI provider implementations
│   ├── mcp/           # MCP client and connectors
│   ├── services/      # Business logic (PRD generation)
│   └── index.ts       # Express server
```

## Adding New MCP Tools

1. Create connector in `src/mcp/`
2. Implement tool-specific methods
3. Integrate with services as needed

## Swift Integration

This API can be called from your Swift app:

```swift
let prdRequest = PRDRequest(
    description: "E-commerce mobile app",
    figmaUrl: "https://figma.com/file/xyz",
    includeDesignAssets: true
)

let response = await apiClient.generatePRD(prdRequest)
```