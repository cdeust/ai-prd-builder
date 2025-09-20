# Debug Mode for PRD Generator

## Default Behavior

**Debug output is ON by default during development!**

You automatically see full prompts and responses when:
- Building with `swift build` (Debug configuration)
- Running with `swift run`
- Using Xcode in Debug scheme

## When Debug Output is Hidden

Debug output is only hidden in production:

### Release Builds
```bash
# Building for release automatically hides debug output
swift build -c release

# Running release build
.build/release/ai-orchestrator interactive
```

### Production Environment
```bash
# For release builds that still need to hide output
PRODUCTION=true .build/release/ai-orchestrator interactive
```

## What Debug Mode Shows

When enabled, you'll see:

1. **Full Prompts Sent**
   ```
   ════════════════════════════════════════════════════════════════════════════════
   📤 SENDING TO APPLE INTELLIGENCE (2456 chars):
   --------------------------------------------------------------------------------
   [Complete prompt text shown here]
   ════════════════════════════════════════════════════════════════════════════════
   ```

2. **Full Responses Received**
   ```
   ════════════════════════════════════════════════════════════════════════════════
   📥 RECEIVED FROM APPLE INTELLIGENCE (8432 chars):
   --------------------------------------------------------------------------------
   [Complete response text shown here]
   ════════════════════════════════════════════════════════════════════════════════
   ```

## Benefits for Development

- **Prompt Engineering**: See exactly what prompts are being sent
- **Response Analysis**: Understand what the AI is generating
- **Debugging**: Identify where issues occur in the generation process
- **Optimization**: Find opportunities to improve prompts and responses

## Production Mode (Hidden Debug)

In production/release builds, you'll see concise output:
```
📤 Sending request to Apple Intelligence (2456 chars)...
⏳ Processing...
📥 Received response (8432 chars)
```

## Build Configurations

| Configuration | Debug Output | Use Case |
|--------------|--------------|----------|
| `swift build` | ✅ Full output | Development & debugging |
| `swift run` | ✅ Full output | Testing & development |
| `swift build -c release` | ❌ Concise | Production deployment |
| Release + `PRODUCTION=true` | ❌ Concise | Production with explicit flag |

## Why This Approach?

- **Developer-friendly**: No need to set flags during development
- **Production-safe**: Automatically hides sensitive data in release builds
- **Debugging by default**: See everything while developing
- **Clean production logs**: Concise output for end users