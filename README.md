# WebPark

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS-blue.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)
[![CI](https://github.com/YOUR_USERNAME/WebPark/workflows/CI/badge.svg)](https://github.com/YOUR_USERNAME/WebPark/actions)

> REST that is a walk in the park! 🌳

WebPark is a lightweight, protocol-oriented Swift networking library that leverages generics and modern Swift concurrency to provide simple, type-safe HTTP interactions with minimal boilerplate.

## Features

- ✨ **Type-safe**: Full generic support with Codable
- ⚡️ **Modern**: Built with Swift 6 and async/await
- 🔐 **Authentication**: Built-in bearer token support with automatic refresh
- 🎯 **Simple API**: Protocol-based design with sensible defaults
- 🧪 **Testable**: Includes mock URL protocol for easy testing
- 🌍 **Cross-platform**: Supports iOS, macOS, tvOS, and watchOS
- 📦 **Zero Dependencies**: Pure Swift, no external frameworks

## Requirements

- macOS 12.0+ / iOS 15.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 15.2+
- Swift 6.2+

## Installation

### Swift Package Manager

Add WebPark to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/WebPark.git", from: "0.2.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/YOUR_USERNAME/WebPark.git`
3. Select version and add to your target

## Quick Start

### 1. Conform to WebPark Protocol

```swift
import WebPark

struct MyAPIClient: WebPark {
    let baseURL = "https://api.example.com"
}
```

### 2. Define Your Models

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}
```

### 3. Add Endpoint Methods

```swift
extension MyAPIClient {
    func getUsers() async throws -> [User] {
        return try await get("/users")
    }
    
    func getUser(id: Int) async throws -> User {
        return try await get("/users/\(id)")
    }
    
    func createUser(_ user: User) async throws -> User {
        return try await post("/users", body: user)
    }
    
    func updateUser(_ user: User) async throws -> User {
        return try await put("/users/\(user.id)", body: user)
    }
    
    func deleteUser(id: Int) async throws {
        try await delete("/users/\(id)")
    }
}
```

### 4. Use It!

```swift
let client = MyAPIClient()

do {
    let users = try await client.getUsers()
    print("Fetched \(users.count) users")
} catch let error as WebParkHttpError {
    print("HTTP Error: \(error.statusCode) - \(error.httpError.description)")
} catch {
    print("Error: \(error)")
}
```

## Advanced Usage

### Query Parameters

```swift
extension MyAPIClient {
    func searchUsers(name: String) async throws -> [User] {
        let queryItems = [URLQueryItem(name: "name", value: name)]
        return try await get("/users", queryItems: queryItems)
    }
}
```

### Authentication

Implement `WebParkTokenServiceProtocol` for authenticated requests:

```swift
actor TokenService: WebParkTokenServiceProtocol {
    private var _token: String
    
    var token: String {
        get async { _token }
    }
    
    init(token: String) {
        self._token = token
    }
    
    func refreshToken() async throws {
        // Your token refresh logic here
        // e.g., call refresh endpoint, update _token
        let newToken = try await performTokenRefresh()
        _token = newToken
    }
    
    private func performTokenRefresh() async throws -> String {
        // Implementation details
        return "new_token_value"
    }
}

struct AuthenticatedAPIClient: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol) {
        self.tokenService = tokenService
    }
}
```

### Custom URLSession

For advanced configuration or testing:

```swift
struct MyAPIClient: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
    
    init(configuration: URLSessionConfiguration = .default) {
        configuration.timeoutIntervalForRequest = 30
        configuration.httpAdditionalHeaders = ["X-Custom-Header": "value"]
        self.urlSession = URLSession(configuration: configuration)
    }
}
```

### Error Handling

WebPark provides two error types:

```swift
do {
    let user = try await client.getUser(id: 123)
} catch let error as WebParkHttpError {
    // HTTP errors (4xx, 5xx)
    switch error.httpError {
    case .unauthorized:
        print("Need to login")
    case .notFound:
        print("User not found")
    case .tooManyRequests:
        print("Rate limited")
    default:
        print("HTTP \(error.statusCode): \(error.description)")
    }
} catch let error as WebParkError {
    // Request construction errors
    switch error {
    case .unableToMakeURL:
        print("Invalid URL")
    case .decodeFailure(let message):
        print("Failed to decode: \(message)")
    case .encodeFailure(let message):
        print("Failed to encode: \(message)")
    default:
        print("Error: \(error)")
    }
} catch {
    // Other errors (network, etc.)
    print("Unexpected error: \(error)")
}
```

## HTTP Methods

WebPark supports all common HTTP methods:
| Method | Usage | Returns |
|--------|-------|---------|
| GET | `get(_:queryItems:)` | `T: Codable` |
| POST | `post(_:body:)` | `T: Codable` |
| PUT | `put(_:body:)` | `T: Codable` |
| PATCH | `patch(_:body:)` | `T: Codable` |
| DELETE | `delete(_:queryItems:)` | `Void` |

## Testing

WebPark includes `URLProtocolMock` for easy testing:

```swift
import Testing
@testable import WebPark

@Suite("API Tests")
struct APITests {
    @Test("Fetch users returns expected data")
    func fetchUsers() async throws {
        // Setup mock response
        let mockData = """
        [{"id": 1, "name": "Alice", "email": "alice@example.com"}]
        """.data(using: .utf8)!
        
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com/users")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        URLProtocolMock.setMock((error: nil, data: mockData, response: response),
                                for: URL(string: "https://api.example.com/users")!)
        
        // Test your client
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        
        let client = MyAPIClient(urlSession: session)
        let users = try await client.getUsers()
        
        #expect(users.count == 1)
        #expect(users[0].name == "Alice")
    }
}
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Roadmap

- [ ] Request retry logic with exponential backoff
- [ ] Download/upload progress tracking
- [ ] Multipart form data support
- [ ] Request cancellation
- [ ] Response caching strategies
- [ ] Certificate pinning

## License

WebPark is available under the MIT license. See [LICENSE](LICENSE) for details.

Copyright © 2022-2025 Dan Giralté

---

Made with ❤️ using Swift




