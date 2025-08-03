#!/bin/bash

# Release script for Calendar MCP Server
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.0.1

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.1"
    exit 1
fi

VERSION=$1

echo "🚀 Preparing release $VERSION"

# Validate version format (basic semver check)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
    echo "❌ Invalid version format. Use semantic versioning (e.g., 1.0.1)"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Please switch to main branch before releasing"
    exit 1
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "❌ Working directory is not clean. Please commit or stash changes"
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
swift test

# Build release
echo "🔨 Building release..."
swift build -c release

# Check if binary was built successfully
if [ ! -f ".build/release/calendar-mcp" ]; then
    echo "❌ Release build failed"
    exit 1
fi

# Update version in Package.swift if needed (manual step for now)
echo "📝 Please update version in Package.swift manually if needed"

# Create git tag
echo "🏷️  Creating git tag v$VERSION"
git tag -a "v$VERSION" -m "Release version $VERSION"

echo "✅ Release $VERSION prepared successfully!"
echo ""
echo "Next steps:"
echo "1. Push the tag: git push origin v$VERSION"
echo "2. Create a GitHub release with the binary"
echo "3. Update CHANGELOG.md with release notes"
echo ""
echo "Binary location: .build/release/calendar-mcp"