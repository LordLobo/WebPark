# WebPark Project Setup Guide

This document describes the project configuration and development workflow for WebPark.

## Project Structure

```
WebPark/
├── .github/
│   ├── workflows/
│   │   └── ci.yml                    # GitHub Actions CI/CD
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md             # Bug report template
│   │   └── feature_request.md        # Feature request template
│   └── pull_request_template.md      # PR template
├── Sources/
│   └── WebPark/                      # Main library source code
├── Tests/
│   └── WebParkTests/                 # Test files
├── scripts/
│   └── tag-release.sh                # Version tagging script
├── .gitignore                        # Git ignore rules
├── .swiftlint.yml                    # SwiftLint configuration
├── CHANGELOG.md                      # Version history
├── CONTRIBUTING.md                   # Contribution guidelines
├── LICENSE                           # MIT License
├── Makefile                          # Development commands
├── Package.swift                     # Swift Package Manager manifest
├── README.md                         # Project documentation
└── SECURITY.md                       # Security policy
```

## Development Workflow

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/WebPark.git
   cd WebPark
   ```

2. **Install development tools**
   ```bash
   make install-tools
   ```

### Daily Development

1. **Build the project**
   ```bash
   make build
   # or
   swift build
   ```

2. **Run tests**
   ```bash
   make test
   # or for verbose output
   make test-verbose
   ```

3. **Lint your code**
   ```bash
   make lint
   # or auto-fix issues
   make lint-fix
   ```

4. **Run all checks**
   ```bash
   make check
   ```

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** and write tests

3. **Update CHANGELOG.md** with your changes

4. **Run checks** before committing
   ```bash
   make check
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add my new feature"
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

### Release Process

1. **Update CHANGELOG.md**
   - Move changes from `[Unreleased]` to a new version section
   - Add release date
   - Follow Keep a Changelog format

2. **Run release checks**
   ```bash
   make release
   ```

3. **Tag the release**
   ```bash
   ./scripts/tag-release.sh 0.3.0
   ```

4. **Push the tag**
   ```bash
   git push origin v0.3.0
   ```

5. **Create GitHub Release**
   - Go to GitHub Releases
   - Draft a new release from the tag
   - Copy relevant CHANGELOG entries
   - Publish release

## Continuous Integration

The project uses GitHub Actions for CI/CD:

### Workflows

- **Test**: Runs on macOS 13 & 14, tests the package
- **Lint**: Runs SwiftLint with strict mode
- **Platforms**: Tests on iOS, tvOS, watchOS, and macOS
- **Code Coverage**: Generates coverage reports and uploads to Codecov

### Triggers

CI runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

## Code Quality Tools

### SwiftLint

Configuration in `.swiftlint.yml`:
- Line length: 120 warning, 150 error
- File length: 500 warning, 1000 error
- Function body length: 50 warning, 100 error
- Force unwrapping disabled in production code
- Custom rules for print statements

Run with:
```bash
make lint
```

### Swift Format

Auto-format code (if installed):
```bash
make format
```

## Testing

### Framework
Uses Swift Testing (not XCTest) with modern macros:
```swift
@Suite("My Tests")
struct MyTests {
    @Test("Description")
    func myTest() async throws {
        #expect(value == expected)
    }
}
```

### Test Requirements
All code must have tests for:
- ✅ Success cases
- ✅ Error handling
- ✅ Edge cases
- ✅ Header validation
- ✅ Request/response verification

### Running Tests
```bash
make test              # Standard output
make test-verbose      # Verbose output
make coverage          # With coverage report
```

## Package Configuration

### Package.swift Features

- **Swift Tools Version**: 6.2
- **Platforms**: macOS 12+, iOS 15+, tvOS 15+, watchOS 8+
- **Swift Language Mode**: Swift 6
- **Upcoming Features Enabled**:
  - BareSlashRegexLiterals
  - ConciseMagicFile
  - ExistentialAny
  - ForwardTrailingClosures
  - ImplicitOpenExistentials
  - StrictConcurrency

### Dependencies

WebPark has **zero external dependencies**, keeping it lightweight and reducing security risks.

## Documentation

### Code Documentation

Use documentation comments for all public APIs:
```swift
/// Brief description
///
/// Detailed explanation if needed.
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
/// - Returns: Description
/// - Throws: Description of errors
public func myFunction(param1: String, param2: Int) async throws -> Result {
    // implementation
}
```

### Generating Docs

```bash
make docs
```

## Git Workflow

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test improvements

### Commit Messages

Follow Conventional Commits:
- `feat: Add new feature`
- `fix: Fix bug`
- `docs: Update documentation`
- `test: Add tests`
- `refactor: Refactor code`
- `perf: Improve performance`
- `chore: Update build config`

### Pull Requests

1. Fill out the PR template completely
2. Link related issues
3. Ensure CI passes
4. Request review
5. Address feedback
6. Merge when approved

## Security

- Report vulnerabilities via email (see SECURITY.md)
- Keep dependencies minimal (currently zero)
- Follow secure coding practices
- Never commit secrets or tokens
- Use HTTPS endpoints only in production

## Versioning

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Support

- 📖 Read the [README](README.md)
- 🐛 Report bugs via [GitHub Issues](https://github.com/YOUR_USERNAME/WebPark/issues)
- 💡 Request features via [GitHub Issues](https://github.com/YOUR_USERNAME/WebPark/issues)
- 🤝 See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines

## Quick Reference

```bash
# Build
make build

# Test
make test

# Lint
make lint

# All checks
make check

# Clean
make clean

# Help
make help
```

## Resources

- [Swift Evolution](https://github.com/apple/swift-evolution)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

Happy coding! 🚀
