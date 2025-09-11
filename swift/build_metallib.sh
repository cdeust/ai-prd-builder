#!/bin/bash

# Build MLX Metal library from Swift MLX sources

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/.build/arm64-apple-macosx/debug"
RELEASE_DIR="$SCRIPT_DIR/.build/arm64-apple-macosx/release"
MLX_CHECKOUT="$SCRIPT_DIR/.build/checkouts/mlx-swift"
MLX_METAL_DIR="$MLX_CHECKOUT/Source/Cmlx/mlx-generated/metal"

echo "Building MLX Metal library from Swift sources..."

# Create build directories if they don't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Find metal compiler
if [ -x "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal" ]; then
    METAL="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal"
    METALLIB="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metallib"
elif [ -x "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal" ]; then
    METAL="/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal"
    METALLIB="/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metallib"
else
    echo "❌ Metal compiler not found. Please install Xcode."
    exit 1
fi

echo "🔧 Using Metal compiler: $METAL"

# Check if MLX Swift checkout exists
if [ ! -d "$MLX_CHECKOUT" ]; then
    echo "❌ MLX Swift not found. Run 'swift build' first to fetch dependencies"
    exit 1
fi

# Check if Metal sources exist
if [ ! -d "$MLX_METAL_DIR" ]; then
    echo "❌ Metal sources not found at $MLX_METAL_DIR"
    exit 1
fi

echo "📦 Found Metal sources at: $MLX_METAL_DIR"

# Create temp directory for build artifacts
TEMP_DIR=$(mktemp -d)
echo "🔧 Building in: $TEMP_DIR"

# Change to metal directory to have proper include paths
cd "$MLX_METAL_DIR"

# Compile each metal file with proper include paths
echo "⚙️ Compiling Metal shaders..."
for metal_file in *.metal; do
    if [ -f "$metal_file" ]; then
        basename="${metal_file%.metal}"
        # Compile with include path for headers
        if "$METAL" -c "$metal_file" \
            -I"$MLX_METAL_DIR" \
            -I"$MLX_CHECKOUT/Source/Cmlx/mlx-generated" \
            -I"$MLX_CHECKOUT/Source/Cmlx/include" \
            -o "$TEMP_DIR/${basename}.air" 2>/dev/null; then
            echo "  ✓ Compiled $metal_file"
        else
            echo "  ⚠️ Skipped $metal_file"
        fi
    fi
done

# Link all .air files into metallib
cd "$TEMP_DIR"
if ls *.air 1> /dev/null 2>&1; then
    echo "🔗 Linking metallib..."
    if "$METALLIB" *.air -o "$BUILD_DIR/default.metallib"; then
        cp "$BUILD_DIR/default.metallib" "$RELEASE_DIR/default.metallib"
        # MLX also looks for mlx.metallib
        cp "$BUILD_DIR/default.metallib" "$BUILD_DIR/mlx.metallib"
        cp "$BUILD_DIR/default.metallib" "$RELEASE_DIR/mlx.metallib"
        echo "✅ Metal library built successfully!"
        echo "   Location: $BUILD_DIR/default.metallib"
    else
        echo "❌ Failed to link metallib"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo "❌ No Metal files could be compiled successfully"
    echo "   Attempting alternate build method..."
    
    # Try to build with all files at once
    cd "$MLX_METAL_DIR"
    if "$METAL" -o "$BUILD_DIR/default.metallib" \
        -I"$MLX_METAL_DIR" \
        -I"$MLX_CHECKOUT/Source/Cmlx/mlx-generated" \
        -I"$MLX_CHECKOUT/Source/Cmlx/include" \
        *.metal 2>/dev/null; then
        cp "$BUILD_DIR/default.metallib" "$RELEASE_DIR/default.metallib"
        # MLX also looks for mlx.metallib
        cp "$BUILD_DIR/default.metallib" "$BUILD_DIR/mlx.metallib"
        cp "$BUILD_DIR/default.metallib" "$RELEASE_DIR/mlx.metallib"
        echo "✅ Metal library built using combined compilation!"
    else
        echo "❌ Failed to build metallib"
        echo "   This requires MLX's CMake build system"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "You can now run:"
echo "  swift run ai-orchestrator interactive"