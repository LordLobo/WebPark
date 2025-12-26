# Contributing to WebPark

Thank you for considering contributing to WebPark! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

## Code of Conduct

This project follows Apple's inclusive and respectful community standards. Please be kind and professional in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/WebPark.git
   cd WebPark
   ```
3. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/my-new-feature
   ```

## Development Process

### Prerequisites

- Xcode 15.2 or later
- Swift 6.2 or later
- SwiftLint (optional but recommended)
  ```bash
  brew install swiftlint
  ```

### Building the Project

```bash
swift build
```

### Running Tests

```bash
swift test
```

### Running SwiftLint

```bash
swiftlint lint
```

## Pull Request Process

1. **Ensure all tests pass** before submitting
2. **Update the CHANGELOG.md** following [Keep a Changelog](https://keepachangelog.com/) format
3. **Update documentation** if you're changing public APIs
4. **Ensure SwiftLint returns no warnings or errors**
5. **Write a clear PR description** explaining:
   - What problem does this solve?
   - What changes were made?
   - Are there any breaking changes?
6. **Link related issues** in the PR description

### PR Title Format

Use conventional commit format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `test:` for adding tests
- `refactor:` for code refactoring
- `perf:` for performance improvements
- `chore:` for maintenance tasks

Example: `feat: Add retry logic for failed requests`

## Coding Standards

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift 6 strict concurrency features
- Prefer Swift-native APIs over older Foundation alternatives
- Use `async/await` for asynchronous code
- Avoid force unwrapping (`!`) and force try (`try!`)
- Use meaningful variable and function names

### Code Organization

- Keep files focused on a single responsibility
- Group related functionality in extensions
- Use `// MARK:` comments to organize code sections
- Add documentation comments (`///`) for all public APIs

### Concurrency

- All public async APIs should use `async throws`
- Use `@Sendable` and actors appropriately
- Follow strict concurrency checking rules
- Never use legacy GCD (`DispatchQueue`) APIs

### Error Handling

- Use typed errors (`WebParkError`, `WebParkHttpError`)
- Provide clear error messages
- Include context in error descriptions

## Testing Requirements

All new code must include tests:

### Required Test Coverage

- ✅ Success cases with valid data
- ✅ Error handling for various HTTP status codes
- ✅ Header validation
- ✅ Request construction verification
- ✅ Response decoding/encoding verification
- ✅ Edge cases and boundary conditions

### Testing Framework

Use Swift Testing (not XCTest):

```swift
import Testing
@testable import WebPark

@Suite("My Feature Tests")
struct MyFeatureTests {
    @Test("Description of what this tests")
    func testSomething() async throws {
        #expect(actual == expected, "Helpful message")
    }
}
```

### Test Organization

- Group related tests in test suites using `@Suite`
- Use descriptive test names
- Keep tests focused and isolated
- Use mocks/stubs for external dependencies

## Documentation

### Code Comments

- Add `///` documentation comments for all public APIs
- Include parameter descriptions and return values
- Provide usage examples where helpful

Example:
```swift
/// Performs a GET request to the specified endpoint
///
/// - Parameters:
///   - endpoint: The API endpoint path (e.g., "/users")
///   - queryItems: Optional query parameters to append to the URL
/// - Returns: The decoded response of type `T`
/// - Throws: `WebParkError` if the request cannot be created or `WebParkHttpError` for HTTP errors
public func get<T: Codable>(_ endpoint: String, queryItems: [URLQueryItem] = []) async throws -> T {
    // implementation
}
```

### README Updates

If you're adding major features:
- Update the README.md with usage examples
- Add to the feature list
- Update code samples if APIs change

### CHANGELOG

Every PR must update CHANGELOG.md:

```markdown
## [Unreleased]

### Added
- New feature description

### Changed
- What changed and why

### Fixed
- Bug fix description
```

## Version Numbers

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Questions?

If you have questions:
- Open an issue for discussion
- Check existing issues and PRs
- Review the README.md and documentation

## License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.
