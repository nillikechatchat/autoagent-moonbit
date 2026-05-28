#!/bin/bash
set -e

# AutoAgent Build Script
# Builds cross-platform native binaries

VERSION="0.1.0"
BUILD_DIR="_build/dist"
BINARY_NAME="autoagent"

echo "Building AutoAgent v${VERSION}..."

# Clean previous builds
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build native binary
echo "Building native binary..."
PATH="$HOME/.moon/bin:$PATH" moon build --target native --release

# Copy binary
cp _build/native/release/build/src/main/main.exe "${BUILD_DIR}/${BINARY_NAME}"

# Copy config template
cp -r .autoagent "${BUILD_DIR}/"

# Create archive
cd "${BUILD_DIR}"
chmod +x "${BINARY_NAME}"
tar -czf "../autoagent-${VERSION}-linux-x86_64.tar.gz" ./*
cd ../..

echo ""
echo "Build complete!"
echo "Binary: ${BUILD_DIR}/${BINARY_NAME}"
echo "Archive: _build/autoagent-${VERSION}-linux-x86_64.tar.gz"
echo ""
echo "Test: ./${BUILD_DIR}/${BINARY_NAME} --help"
