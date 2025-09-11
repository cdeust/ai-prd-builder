#!/bin/bash

# Complete build script for Swift AI Orchestrator

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔨 Building Swift AI Orchestrator..."
echo "===================================="

# Build the Swift package
echo "📦 Building Swift package..."
swift build

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"

# Setup Metal library
echo ""
echo "🔧 Setting up Metal library..."
"$SCRIPT_DIR/build_metallib.sh"

if [ $? -ne 0 ]; then
    echo "❌ Metal library setup failed"
    exit 1
fi

echo ""
echo "🎉 Build complete!"
echo ""
echo "To run the interactive PRD assistant:"
echo "  swift run ai-orchestrator interactive"
echo ""
echo "Or run directly:"
echo "  .build/arm64-apple-macosx/debug/ai-orchestrator interactive"
