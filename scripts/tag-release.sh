#!/bin/bash

# Release Tagging Script for WebPark
# Usage: ./scripts/tag-release.sh <version>
# Example: ./scripts/tag-release.sh 1.2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if version argument is provided
if [ -z "$1" ]; then
    print_error "Version number is required"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.0"
    exit 1
fi

VERSION=$1
TAG_NAME="v${VERSION}"

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 1.2.0 or 1.2.0-beta.1)"
    exit 1
fi

print_info "Preparing to create release ${TAG_NAME}"

# Check if we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "You are not on the main branch (current: ${CURRENT_BRANCH})"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory is not clean. Please commit or stash your changes."
    git status --short
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    print_error "Tag ${TAG_NAME} already exists"
    exit 1
fi

# Pull latest changes
print_info "Pulling latest changes..."
git pull origin main

# Check if CHANGELOG.md has an entry for this version
print_info "Checking CHANGELOG.md..."
if ! grep -q "## \[${VERSION}\]" CHANGELOG.md; then
    print_error "CHANGELOG.md does not contain an entry for version ${VERSION}"
    print_info "Please update CHANGELOG.md with release notes for ${VERSION}"
    exit 1
fi

# Run tests
print_info "Running tests..."
if ! swift test; then
    print_error "Tests failed. Please fix the failing tests before creating a release."
    exit 1
fi

# Run SwiftLint if available
if command -v swiftlint &> /dev/null; then
    print_info "Running SwiftLint..."
    if ! swiftlint lint; then
        print_warning "SwiftLint found issues. Please fix them before releasing."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    print_warning "SwiftLint not found. Skipping lint check."
fi

# Extract changelog entry for this version
print_info "Extracting changelog for ${VERSION}..."
CHANGELOG_ENTRY=$(awk "/## \[${VERSION}\]/,/## \[/{if(/## \[/&&++c==2)exit;if(c==1)print}" CHANGELOG.md)

if [ -z "$CHANGELOG_ENTRY" ]; then
    print_error "Could not extract changelog entry for ${VERSION}"
    exit 1
fi

# Show the changelog entry
print_info "Changelog entry for ${VERSION}:"
echo "---"
echo "$CHANGELOG_ENTRY"
echo "---"

# Confirm release
read -p "Do you want to create release ${TAG_NAME}? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Release cancelled"
    exit 0
fi

# Create annotated tag
print_info "Creating tag ${TAG_NAME}..."
git tag -a "$TAG_NAME" -m "Release version ${VERSION}

${CHANGELOG_ENTRY}"

# Push tag
print_info "Pushing tag to origin..."
git push origin "$TAG_NAME"

print_info "✅ Release ${TAG_NAME} created successfully!"
print_info ""
print_info "Next steps:"
print_info "1. Go to GitHub and create a release from the tag"
print_info "2. Copy the changelog entry into the release notes"
print_info "3. Publish the release"
print_info ""
print_info "GitHub will automatically:"
print_info "- Run CI tests"
print_info "- Create a GitHub Release"
print_info "- Make the release available via Swift Package Manager"
