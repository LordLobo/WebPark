# Changelog

All notable changes to WebPark will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- A non-HTTP response is no longer treated as a success. Previously the
  `response as? HTTPURLResponse` cast was part of an `if let`, so a failed cast skipped the
  status check and fell through to decoding. Now throws `WebParkError.unexpectedResponse`.
- `localizedDescription` on `WebParkError` and `WebParkHttpError` no longer returns
  "The operation couldn't be completed". Both now conform to `LocalizedError`, so the
  message survives being caught as `any Error` — which is what `catch` actually binds.
- `POST`, `PUT`, and `PATCH` can now target endpoints that reply `204 No Content`; the
  value-returning overloads previously failed decoding on an empty body.
- CI `check-package` job ran `swift package diagnose`, which is not a real subcommand and
  always failed. Now runs `swift package dump-package`.
- `CHANGELOG.md` moved from `Tests/WebParkTests/` to the repository root. It was raising a
  SwiftPM "unhandled file" warning in the test target, and the release workflow reads the
  root path, so generated release notes were always empty.
- Replaced `YOUR_USERNAME` placeholders in README links and badges, and dropped the
  placeholder `cname` from the documentation deploy job.

### Added
- `Void`-returning overloads of `post(_:body:)`, `put(_:body:)`, and `patch(_:body:)` for
  endpoints that return no content.
- `WebParkError.unexpectedResponse` for replies that are not HTTP responses.
- Comprehensive package configuration setup
  - `.swiftlint.yml` with sensible Swift linting rules
  - GitHub Actions CI/CD workflow for automated testing across platforms
  - `.gitignore` with Swift package and Xcode exclusions
  - Enhanced `Package.swift` with Swift 6 language mode and upcoming features
  - `CONTRIBUTING.md` with detailed contribution guidelines
  - `LICENSE` file with MIT license
  - GitHub issue templates for bug reports and feature requests
  - Pull request template
  - Release tagging script (`scripts/tag-release.sh`)
- Significantly enhanced README with:
  - Installation instructions
  - Quick start guide
  - Advanced usage examples
  - Error handling documentation
  - Testing guide
  - CI badges and roadmap

### Changed
- `createRequest` now returns a non-optional `URLRequest`. It only ever threw on failure,
  so the `guard let ... else { throw .unableToMakeRequest }` at every call site was
  unreachable.
- Status-code checking and response handling consolidated into a single internal
  `perform(_:)` helper, replacing seven copies of the same block.
- Removed the hand-written `WebParkError.==`; the synthesized `Equatable` conformance is
  equivalent and does not need updating when a case is added.
- Dropped stale `@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)` annotations
  from the HTTP method extensions; those versions are below the package deployment floor.
- Package.swift now enforces Swift 6 strict concurrency features
- README completely rewritten with better examples and documentation

## [0.2.0] - 2024-12-25

### Added
- PATCH HTTP method support via `patch(_:body:)` method
- Comprehensive test suite for PATCH operations including:
  - Success cases with valid data
  - Error handling for 404 Not Found responses
  - Error handling for 409 Conflict responses
  - Content-Type header validation
  - Request body encoding verification
  - Response decoding verification

### Changed
- None

### Fixed
- None

## [0.1.0] - Initial Release

### Added
- Core WebPark protocol for REST API interactions
- GET, POST, PUT, and DELETE HTTP methods
- Token service protocol for authentication
- Async/await support using Swift Concurrency
- Comprehensive error handling with `WebParkError` and `WebParkHttpError`
- Support for macOS 12+, iOS 15+, tvOS 15+, watchOS 8+
