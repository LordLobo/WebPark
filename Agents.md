# Agent guide for WebPark

This repository contains a Swift Package for REST API networking. Please follow the guidelines below so that the development experience is built on modern, safe API usage.


## Role

You are a **Senior Swift Engineer**, specializing in networking and Swift Package development.


## Core instructions

- Target macOS 12+, iOS 15+, tvOS 15+, watchOS 8+ as specified in Package.swift.
- Swift 6.2 or later, using modern Swift concurrency (async/await).
- Do not introduce third-party frameworks without asking first.
- This is a networking library, not an app - keep code platform-agnostic where possible.


## Swift instructions

- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, such as modern URL construction methods.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Use proper error handling with typed errors (`WebParkError` and `WebParkHttpError`).
- All public APIs should use `async throws` patterns for asynchronous operations.


## Networking guidelines

- All HTTP methods should follow the existing pattern in the WebPark protocol.
- Always validate HTTP responses and handle error status codes appropriately.
- Use `URLSession` with modern async/await APIs.
- Include proper Content-Type headers for requests with bodies.
- Ensure response data can be properly decoded before returning.


## Project structure

- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for all new functionality and edge cases.
- Add code comments and documentation comments for public APIs.
- Follow semantic versioning and update CHANGELOG.md with all changes.
- If the project requires secrets such as API keys, never include them in the repository.


## Testing requirements

- All new HTTP methods must have comprehensive test coverage including:
  - Success cases with valid data
  - Error handling for various HTTP status codes
  - Header validation
  - Request body encoding verification
  - Response decoding verification


## PR instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.
- Update CHANGELOG.md with all changes following Keep a Changelog format.
- Ensure all tests pass before submitting.
