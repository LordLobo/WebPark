# Changelog

All notable changes to WebPark will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
