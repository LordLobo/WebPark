#!/bin/bash

# WebPark Version Tagging Script
# Usage: ./scripts/tag-release.sh <version>
# Example: ./scripts/tag-release.sh 0.3.0

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Error: Version number required"
    echo "Usage: ./scripts/tag-release.sh <version>"
    echo "Example: ./scripts/tag-release.sh 0.3.0"
    exit 1
fi

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Must be semantic versioning (e.g., 0.3.0)"
    exit 1
fi

echo "🏷️  Preparing to tag version $VERSION"

# Check if working directory is clean
if [[ -n $(git status -s) ]]; then
    echo "Error: Working directory is not clean. Commit or stash your changes."
    exit 1
fi

# Check if CHANGELOG has been updated
if ! grep -q "\[$VERSION\]" CHANGELOG.md; then
    echo "⚠️  Warning: CHANGELOG.md doesn't seem to mention version $VERSION"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ensure we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Warning: Not on main branch (currently on $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run tests
echo "🧪 Running tests..."
swift test

# Run SwiftLint if available
if command -v swiftlint &> /dev/null; then
    echo "🔍 Running SwiftLint..."
    swiftlint lint
else
    echo "⚠️  SwiftLint not found, skipping..."
fi

# Create tag
echo "📝 Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION"

echo "✅ Tag v$VERSION created successfully!"
echo ""
echo "Next steps:"
echo "1. Push the tag: git push origin v$VERSION"
echo "2. Create a GitHub release from the tag"
echo "3. Update any package consumers"
