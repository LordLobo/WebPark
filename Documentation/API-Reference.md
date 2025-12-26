# WebPark API Reference

Complete API documentation for WebPark networking library.

## Table of Contents

- [Core Protocols](#core-protocols)
- [HTTP Methods](#http-methods)
- [Error Types](#error-types)
- [URLRequest Extensions](#urlrequest-extensions)
- [Testing Utilities](#testing-utilities)

---

## Core Protocols

### WebPark Protocol

The main protocol that defines a REST API client.

```swift
public protocol WebPark {
    var baseURL: String { get }
    var urlSession: URLSession { get }
    var tokenService: WebParkTokenServiceProtocol? { get }
}
```

#### Properties

##### `baseURL`
```swift
var baseURL: String { get }
```
The base URL for your API endpoint (e.g., `"https://api.example.com"`).

This value is concatenated with relative endpoint paths when building requests.

**Required**: Yes

**Example**:
```swift
struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
}
```

---

##### `urlSession`
```swift
var urlSession: URLSession { get }
```
The `URLSession` used to execute network requests.

A default implementation provides `URLSession.shared` via a protocol extension. Override by supplying your own session when needed (e.g., for custom configuration or testing with mocked sessions).

**Required**: No (defaults to `URLSession.shared`)

**Example**:
```swift
struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
}
```

---

##### `tokenService`
```swift
var tokenService: WebParkTokenServiceProtocol? { get }
```
Optional token service used to attach and refresh bearer tokens for authenticated requests.

When present, HTTP methods automatically add an `Authorization: Bearer <token>` header using `tokenService.token`.

**Required**: No (defaults to `nil`)

**Example**:
```swift
struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol? = nil) {
        self.tokenService = tokenService
    }
}
```

---

### WebParkTokenServiceProtocol

Protocol for providing authentication tokens.

```swift
public protocol WebParkTokenServiceProtocol {
    var token: String { get }
    func refreshToken() async throws
}
```

#### Properties

##### `token`
```swift
var token: String { get }
```
The current bearer token to be used in Authorization headers.

---

#### Methods

##### `refreshToken()`
```swift
func refreshToken() async throws
```
Refreshes the current token, typically called when receiving a 401 response.

**Throws**: An error if the token refresh fails

**Example Implementation**:
```swift
actor TokenService: WebParkTokenServiceProtocol {
    private var _token: String
    
    var token: String {
        _token
    }
    
    init(initialToken: String) {
        self._token = initialToken
    }
    
    func refreshToken() async throws {
        // Call your refresh endpoint
        let request = URLRequest(url: URL(string: "https://api.example.com/refresh")!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        self._token = response.accessToken
    }
}
```

---

### WebParkAsyncTokenServiceProtocol

Extended token service protocol with async property access and authentication state.

```swift
public protocol WebParkAsyncTokenServiceProtocol: Sendable {
    var token: String { get async }
    func refreshToken() async throws
    var isAuthenticated: Bool { get async }
}
```

#### Properties

##### `token`
```swift
var token: String { get async }
```
The current bearer token (async accessor).

---

##### `isAuthenticated`
```swift
var isAuthenticated: Bool { get async }
```
Indicates whether the token service is currently authenticated.

---

## HTTP Methods

All HTTP method extensions are available on types conforming to `WebPark` and are marked with:
```swift
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
```

### GET Requests

Retrieve resources from the server.

#### `get(_:)`
```swift
func get<T: Codable>(_ endpoint: String) async throws -> T
```
Performs a GET request and decodes the response.

**Parameters**:
- `endpoint`: The API endpoint path (e.g., `"/users"`)

**Returns**: The decoded response object of type `T`

**Throws**:
- `WebParkError.unableToMakeRequest` if the request cannot be created
- `WebParkHttpError` if the server returns an error status code (≥400)
- `DecodingError` if the response cannot be decoded

**Example**:
```swift
struct User: Codable {
    let id: Int
    let name: String
}

let users: [User] = try await api.get("/users")
```

---

#### `get(_:queryItems:)`
```swift
func get<T: Codable>(_ endpoint: String, 
                     queryItems: [URLQueryItem]) async throws -> T
```
Performs a GET request with query parameters and decodes the response.

**Parameters**:
- `endpoint`: The API endpoint path
- `queryItems`: Query parameters to append to the URL

**Returns**: The decoded response object of type `T`

**Throws**: Same as `get(_:)`

**Example**:
```swift
let query = [
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "10")
]
let users: [User] = try await api.get("/users", queryItems: query)
// Requests: /users?page=1&limit=10
```

---

### POST Requests

Create new resources on the server.

#### `post(_:body:)`
```swift
func post<T: Codable, D: Codable>(_ endpoint: String, 
                                   body: D) async throws -> T
```
Performs a POST request with a JSON body and decodes the response.

**Parameters**:
- `endpoint`: The API endpoint path (e.g., `"/users"`)
- `body`: The request body to encode as JSON

**Returns**: The decoded response object of type `T`

**Throws**:
- `WebParkError.unableToMakeRequest` if the request cannot be created
- `WebParkError.encodeFailure` if the body cannot be encoded
- `WebParkHttpError` if the server returns an error status code (≥400)
- `DecodingError` if the response cannot be decoded

**Example**:
```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

let request = CreateUserRequest(name: "Alice", email: "alice@example.com")
let newUser: User = try await api.post("/users", body: request)
```

---

### PUT Requests

Replace or update existing resources on the server.

#### `put(_:body:)`
```swift
func put<T: Codable, D: Codable>(_ endpoint: String, 
                                  body: D) async throws -> T
```
Performs a PUT request with a JSON body and decodes the response.

**Parameters**:
- `endpoint`: The API endpoint path (e.g., `"/users/123"`)
- `body`: The request body to encode as JSON

**Returns**: The decoded response object of type `T`

**Throws**: Same as `post(_:body:)`

**Example**:
```swift
let update = CreateUserRequest(name: "Alice Smith", email: "alice@example.com")
let updated: User = try await api.put("/users/123", body: update)
```

---

### PATCH Requests

Partially update existing resources on the server.

#### `patch(_:body:)`
```swift
func patch<T: Codable, D: Codable>(_ endpoint: String, 
                                    body: D) async throws -> T
```
Performs a PATCH request with a JSON body and decodes the response.

**Parameters**:
- `endpoint`: The API endpoint path (e.g., `"/users/123"`)
- `body`: The partial update body to encode as JSON

**Returns**: The decoded response object of type `T`

**Throws**: Same as `post(_:body:)`

**Example**:
```swift
struct NameUpdate: Codable {
    let name: String
}

let patch = NameUpdate(name: "Alice J. Smith")
let updated: User = try await api.patch("/users/123", body: patch)
```

---

### DELETE Requests

Remove resources from the server.

#### `delete(_:)`
```swift
func delete(_ endpoint: String) async throws
```
Performs a DELETE request.

**Parameters**:
- `endpoint`: The API endpoint path (e.g., `"/users/123"`)

**Throws**:
- `WebParkError.unableToMakeRequest` if the request cannot be created
- `WebParkHttpError` if the server returns an error status code (≥400)

**Example**:
```swift
try await api.delete("/users/123")
```

---

#### `delete(_:queryItems:)`
```swift
func delete(_ endpoint: String, 
            queryItems: [URLQueryItem]) async throws
```
Performs a DELETE request with query parameters.

**Parameters**:
- `endpoint`: The API endpoint path
- `queryItems`: Query parameters to append to the URL

**Throws**: Same as `delete(_:)`

**Example**:
```swift
let query = [URLQueryItem(name: "cascade", value: "true")]
try await api.delete("/users/123", queryItems: query)
// Requests: /users/123?cascade=true
```

---

## Error Types

### WebParkError

Library-specific errors for request/response handling.

```swift
public enum WebParkError: Error, Equatable, CustomStringConvertible
```

#### Cases

##### `.unableToMakeURL`
Failed to create a URL from the provided base URL and endpoint.

**Common Causes**:
- Invalid characters in base URL or endpoint
- Malformed URL components
- Non-HTTP/HTTPS scheme

---

##### `.unableToMakeRequest`
Failed to create a URLRequest.

---

##### `.decodeFailure(underlying: String)`
Failed to decode the response data.

**Associated Value**: Description of the decoding error

**Example**:
```swift
catch let error as WebParkError {
    if case .decodeFailure(let message) = error {
        print("Decoding failed: \(message)")
    }
}
```

---

##### `.unableToMakeAuthdRequest`
Failed to create an authenticated request (token service issue).

---

##### `.encodeFailure(underlying: String)`
Failed to encode the request body.

**Associated Value**: Description of the encoding error

---

### WebParkHttpError

HTTP status code errors (4xx and 5xx responses).

```swift
public struct WebParkHttpError: Error, Equatable, CustomStringConvertible
```

#### Properties

##### `httpError`
```swift
let httpError: ErrorResponseCode
```
The categorized HTTP error type.

---

##### `statusCode`
```swift
let statusCode: Int
```
The actual HTTP status code from the response.

---

#### Initializers

##### `init(_:)`
```swift
public init(_ statusCode: Int)
```
Creates an HTTP error from a status code.

**Example**:
```swift
let error = WebParkHttpError(404)
print(error.description) // "HTTP 404: Not Found"
```

---

### ErrorResponseCode

Enumeration of common HTTP error status codes.

```swift
public enum ErrorResponseCode: Int, Sendable, CaseIterable
```

#### Cases

| Case | Status Code | Description |
|------|-------------|-------------|
| `.badRequest` | 400 | Bad Request |
| `.unauthorized` | 401 | Unauthorized |
| `.forbidden` | 403 | Forbidden |
| `.notFound` | 404 | Not Found |
| `.methodNotAllowed` | 405 | Method Not Allowed |
| `.conflict` | 409 | Conflict |
| `.unprocessableEntity` | 422 | Unprocessable Entity |
| `.tooManyRequests` | 429 | Too Many Requests |
| `.internalServerError` | 500 | Internal Server Error |
| `.notImplemented` | 501 | Not Implemented |
| `.badGateway` | 502 | Bad Gateway |
| `.serviceUnavailable` | 503 | Service Unavailable |
| `.gatewayTimeout` | 504 | Gateway Timeout |
| `.unhandledResponseCode` | 0 | Unhandled Response Code |

**Example**:
```swift
catch let error as WebParkHttpError {
    switch error.httpError {
    case .unauthorized:
        // Refresh token and retry
        try await tokenService.refreshToken()
    case .notFound:
        // Handle missing resource
        print("Resource not found")
    case .tooManyRequests:
        // Handle rate limiting
        try await Task.sleep(for: .seconds(60))
    default:
        throw error
    }
}
```

---

## URLRequest Extensions

Convenience methods for modifying URLRequests.

### `addingBearerAuthorization(token:)`
```swift
public func addingBearerAuthorization(token: String) -> URLRequest
```
Returns a new request with a Bearer token Authorization header.

**Parameters**:
- `token`: The bearer token

**Returns**: A new URLRequest with the Authorization header set

**Example**:
```swift
var request = URLRequest(url: url)
request = request.addingBearerAuthorization(token: "abc123")
// Sets: Authorization: Bearer abc123
```

---

### `acceptingJSON()`
```swift
public func acceptingJSON() -> URLRequest
```
Returns a new request that accepts JSON responses.

**Returns**: A new URLRequest with Accept header set to `application/json`

**Example**:
```swift
var request = URLRequest(url: url)
request = request.acceptingJSON()
// Sets: Accept: application/json
```

---

### `sendingJSON()`
```swift
public func sendingJSON() -> URLRequest
```
Returns a new request configured to send JSON data.

**Returns**: A new URLRequest with Content-Type header set to `application/json`

**Example**:
```swift
var request = URLRequest(url: url)
request = request.sendingJSON()
// Sets: Content-Type: application/json
```

---

## Testing Utilities

### URLProtocolMock

Mock URLProtocol for testing network interactions without actual HTTP requests.

```swift
class URLProtocolMock: URLProtocol
```

#### Methods

##### `setMock(_:for:)`
```swift
static func setMock(_ entry: (error: Error?, 
                              data: Data?, 
                              response: HTTPURLResponse?), 
                    for url: URL)
```
Set a mock response for a specific URL.

**Parameters**:
- `entry`: Tuple containing optional error, data, and HTTP response
- `url`: The URL to mock

**Example**:
```swift
let url = URL(string: "https://api.example.com/users")!
let mockData = try JSONEncoder().encode([User(id: 1, name: "Alice")])

URLProtocolMock.setMock((
    error: nil,
    data: mockData,
    response: HTTPURLResponse(url: url, statusCode: 200, 
                             httpVersion: nil, headerFields: nil)
), for: url)
```

---

##### `setMock(_:)`
```swift
static func setMock(_ entries: [(URL, (error: Error?, 
                                       data: Data?, 
                                       response: HTTPURLResponse?))])
```
Set multiple mock entries at once.

**Parameters**:
- `entries`: Array of URL and mock response tuples

---

##### `removeAllMocks()`
```swift
static func removeAllMocks()
```
Remove all mock responses.

**Example**:
```swift
// Cleanup after tests
URLProtocolMock.removeAllMocks()
```

---

##### `removeMocks(for:)`
```swift
static func removeMocks(for urls: [URL])
```
Remove mocks for specific URLs only.

**Parameters**:
- `urls`: Array of URLs to remove mocks for

---

#### Usage in Tests

```swift
import Testing
@testable import WebPark

@Suite("API Tests")
struct APITests {
    
    func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
    
    @Test("Successful GET request")
    func testGetSuccess() async throws {
        let mockSession = createMockSession()
        let api = MyAPI(urlSession: mockSession)
        
        let url = URL(string: "https://api.example.com/users")!
        let mockData = try JSONEncoder().encode([User(id: 1, name: "Test")])
        
        URLProtocolMock.setMock((
            error: nil,
            data: mockData,
            response: HTTPURLResponse(url: url, statusCode: 200,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        let users: [User] = try await api.get("/users")
        #expect(users.count == 1)
        #expect(users[0].name == "Test")
    }
}
```

---

## Best Practices

### 1. Organize API Clients by Feature

```swift
// UserAPI.swift
extension MyAPI {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func getUser(id: Int) async throws -> User {
        try await get("/users/\(id)")
    }
}

// ProductAPI.swift
extension MyAPI {
    func getProducts() async throws -> [Product] {
        try await get("/products")
    }
}
```

### 2. Use Separate Types for Requests and Responses

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

struct UserResponse: Codable {
    let id: Int
    let name: String
    let email: String
    let createdAt: Date
}
```

### 3. Handle Errors Appropriately

```swift
do {
    let user = try await api.getUser(id: id)
    return user
} catch let error as WebParkHttpError where error.httpError == .notFound {
    return nil // Return nil for not found
} catch let error as WebParkHttpError where error.httpError == .unauthorized {
    try await tokenService.refreshToken()
    return try await api.getUser(id: id) // Retry once
} catch {
    // Log and rethrow
    logger.error("Failed to fetch user: \(error)")
    throw error
}
```

### 4. Use Actors for Thread-Safe Token Services

```swift
actor TokenService: WebParkTokenServiceProtocol {
    private var _token: String
    private var isRefreshing = false
    
    var token: String { _token }
    
    func refreshToken() async throws {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Perform refresh
        _token = try await performTokenRefresh()
    }
}
```

---

## See Also

- [README.md](../README.md) - Quick start and examples
- [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute
- [CHANGELOG.md](../CHANGELOG.md) - Version history
