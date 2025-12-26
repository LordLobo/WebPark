.PHONY: build test clean lint format help

# Default target
.DEFAULT_GOAL := help

## build: Build the package
build:
	@echo "🔨 Building WebPark..."
	swift build

## test: Run all tests
test:
	@echo "🧪 Running tests..."
	swift test

## test-verbose: Run tests with verbose output
test-verbose:
	@echo "🧪 Running tests (verbose)..."
	swift test --verbose

## clean: Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf .swiftpm

## lint: Run SwiftLint
lint:
	@echo "🔍 Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
		exit 1; \
	fi

## lint-fix: Run SwiftLint and auto-fix issues
lint-fix:
	@echo "🔧 Running SwiftLint autocorrect..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --fix; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
		exit 1; \
	fi

## format: Format code with swift-format (if available)
format:
	@echo "✨ Formatting code..."
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format -i -r Sources Tests; \
	else \
		echo "⚠️  swift-format not installed. Install with: brew install swift-format"; \
		exit 1; \
	fi

## coverage: Generate code coverage report
coverage:
	@echo "📊 Generating coverage report..."
	swift test --enable-code-coverage
	@echo "Coverage data generated in .build/debug/codecov/"

## docs: Generate documentation (requires DocC)
docs:
	@echo "📚 Generating documentation..."
	swift package generate-documentation

## update: Update package dependencies
update:
	@echo "📦 Updating dependencies..."
	swift package update

## resolve: Resolve package dependencies
resolve:
	@echo "🔄 Resolving dependencies..."
	swift package resolve

## check: Run all checks (build, test, lint)
check: build test lint
	@echo "✅ All checks passed!"

## install-tools: Install development tools
install-tools:
	@echo "🛠️  Installing development tools..."
	@if ! command -v swiftlint >/dev/null 2>&1; then \
		echo "Installing SwiftLint..."; \
		brew install swiftlint; \
	else \
		echo "✓ SwiftLint already installed"; \
	fi
	@if ! command -v swift-format >/dev/null 2>&1; then \
		echo "Installing swift-format..."; \
		brew install swift-format; \
	else \
		echo "✓ swift-format already installed"; \
	fi

## release: Prepare for release (run all checks)
release: clean check
	@echo "🚀 Ready for release!"
	@echo "Don't forget to:"
	@echo "  1. Update CHANGELOG.md"
	@echo "  2. Bump version in relevant files"
	@echo "  3. Run: ./scripts/tag-release.sh <version>"

## help: Show this help message
help:
	@echo "WebPark Makefile Commands:"
	@echo ""
	@grep -E '^## [a-zA-Z_-]+:' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ": "}; {printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2}' | \
		sed 's/## //'
	@echo ""
	@echo "Examples:"
	@echo "  make build          # Build the project"
	@echo "  make test           # Run tests"
	@echo "  make check          # Build, test, and lint"
	@echo "  make install-tools  # Install dev tools"
