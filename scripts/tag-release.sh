#!/bin/bash

# Release Tagging Script for WebPark
# Usage: ./scripts/tag-release.sh <version> [--promote]
# Example: ./scripts/tag-release.sh 1.2.0
#
# Validates the working tree, runs the same gates CI runs, then creates and pushes an
# annotated `v<version>` tag. Pushing the tag starts the CI workflow, whose `release` job
# creates the GitHub Release using the CHANGELOG.md section for this version.
#
# With --promote, an existing `## [Unreleased]` heading is renamed to `## [<version>] - <date>`
# and committed before tagging.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Run from the repository root regardless of where the script was invoked from.
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Check if version argument is provided
if [ $# -lt 1 ]; then
    print_error "Version number is required"
    echo "Usage: $0 <version> [--promote]"
    echo "Example: $0 1.2.0"
    exit 1
fi

VERSION=$1
PROMOTE=false
if [ "${2:-}" = "--promote" ]; then
    PROMOTE=true
fi

TAG_NAME="v${VERSION}"

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 1.2.0 or 1.2.0-beta.1)"
    exit 1
fi

# Prints the body of a CHANGELOG.md version section, stopping at the next `## [` heading.
# A naive awk range `/## \[$VERSION\]/,/## \[/` collapses to a single line, because the
# opening line also matches the closing pattern.
changelog_section() {
    awk -v ver="$1" '
        $0 ~ "^## \\[" ver "\\]" { inside = 1; next }
        inside && /^## \[/ { exit }
        inside { print }
    ' CHANGELOG.md
}

# SwiftLint and Swift Testing both need a real Xcode toolchain. If DEVELOPER_DIR is unset
# and xcode-select points at the Command Line Tools, `swift test` fails to load the
# Swift Testing macro plugin and SwiftLint cannot dlopen sourcekitd.
resolve_toolchain() {
    if [ -n "${DEVELOPER_DIR:-}" ]; then
        return
    fi

    local selected
    selected=$(xcode-select -p 2>/dev/null || true)
    if [[ "$selected" != *CommandLineTools* ]]; then
        return
    fi

    local newest
    newest=$(find /Applications -maxdepth 1 -name 'Xcode*.app' 2>/dev/null | sort -V | tail -1)
    if [ -z "$newest" ]; then
        print_error "xcode-select points at the Command Line Tools and no Xcode.app was found."
        print_error "Install Xcode, or run: sudo xcode-select -s /Applications/Xcode.app"
        exit 1
    fi

    export DEVELOPER_DIR="${newest}/Contents/Developer"
    print_warning "xcode-select points at the Command Line Tools; using ${newest} for this run."
    print_warning "To make this permanent: sudo xcode-select -s ${newest}"
}

print_info "Preparing to create release ${TAG_NAME}"

resolve_toolchain

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

# Check if tag already exists, locally or on the remote
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    print_error "Tag ${TAG_NAME} already exists locally"
    exit 1
fi
if [ -n "$(git ls-remote --tags origin "refs/tags/${TAG_NAME}" 2>/dev/null)" ]; then
    print_error "Tag ${TAG_NAME} already exists on origin"
    exit 1
fi

# Pull latest changes
print_info "Pulling latest changes..."
git pull --ff-only origin "$CURRENT_BRANCH"

# Check if CHANGELOG.md has an entry for this version, optionally promoting Unreleased
print_info "Checking CHANGELOG.md..."
if ! grep -q "^## \[${VERSION}\]" CHANGELOG.md; then
    if [ "$PROMOTE" = true ] && grep -q "^## \[Unreleased\]" CHANGELOG.md; then
        if [ -z "$(changelog_section Unreleased | tr -d '[:space:]')" ]; then
            print_error "## [Unreleased] exists but is empty; nothing to release."
            exit 1
        fi

        TODAY=$(date +%Y-%m-%d)
        print_info "Promoting ## [Unreleased] to ## [${VERSION}] - ${TODAY}"
        # BSD and GNU sed disagree on -i, so write through a temp file instead.
        sed "s/^## \[Unreleased\]$/## [${VERSION}] - ${TODAY}/" CHANGELOG.md > CHANGELOG.md.tmp
        mv CHANGELOG.md.tmp CHANGELOG.md

        git add CHANGELOG.md
        git commit -m "Release ${VERSION}"
        print_info "Committed CHANGELOG.md promotion"
    else
        print_error "CHANGELOG.md does not contain an entry for version ${VERSION}"
        print_info "Either add a '## [${VERSION}]' section, or rerun with --promote to"
        print_info "rename the existing '## [Unreleased]' heading to this version."
        exit 1
    fi
fi

# Extract changelog entry for this version
print_info "Extracting changelog for ${VERSION}..."
CHANGELOG_ENTRY=$(changelog_section "$VERSION")

if [ -z "$(printf '%s' "$CHANGELOG_ENTRY" | tr -d '[:space:]')" ]; then
    print_error "The '## [${VERSION}]' section in CHANGELOG.md is empty"
    exit 1
fi

# Run tests
print_info "Running tests..."
if ! swift test; then
    print_error "Tests failed. Please fix the failing tests before creating a release."
    exit 1
fi

# Run SwiftLint if available, with the same --strict gate CI uses
if command -v swiftlint &> /dev/null; then
    print_info "Running SwiftLint (--strict, as CI does)..."
    if ! swiftlint lint --strict; then
        print_warning "SwiftLint found issues. CI runs --strict and will fail on these."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    print_warning "SwiftLint not found. Skipping lint check."
fi

# Show the changelog entry
print_info "Changelog entry for ${VERSION}:"
echo "---"
echo "$CHANGELOG_ENTRY"
echo "---"

# Confirm release
read -p "Do you want to create and push tag ${TAG_NAME}? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Release cancelled"
    exit 0
fi

# If --promote created a commit, it needs to reach the remote before the tag.
if [ "$PROMOTE" = true ]; then
    print_info "Pushing ${CURRENT_BRANCH}..."
    git push origin "$CURRENT_BRANCH"
fi

# Create annotated tag
print_info "Creating tag ${TAG_NAME}..."
git tag -a "$TAG_NAME" -m "Release version ${VERSION}

${CHANGELOG_ENTRY}"

# Push tag
print_info "Pushing tag to origin..."
git push origin "$TAG_NAME"

print_info "✅ Tag ${TAG_NAME} pushed successfully!"
print_info ""
print_info "CI is now running for this tag and will, once the test jobs pass:"
print_info "  - create the GitHub Release for ${TAG_NAME}"
print_info "  - use the CHANGELOG.md section for ${VERSION} as the release notes"
print_info ""
print_info "Watch it with:  gh run watch"
print_info "Then verify:    gh release view ${TAG_NAME}"
print_info ""
print_info "The version becomes resolvable by Swift Package Manager as soon as the tag exists."
