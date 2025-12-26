# Advanced Usage Guide

This guide covers advanced WebPark patterns and techniques for real-world applications.

## Table of Contents

- [Token Refresh Strategy](#token-refresh-strategy)
- [Custom URLSession Configuration](#custom-urlsession-configuration)
- [Error Recovery Patterns](#error-recovery-patterns)
- [Testing Strategies](#testing-strategies)
- [Performance Optimization](#performance-optimization)
- [Dependency Injection](#dependency-injection)
- [Pagination](#pagination)
- [Rate Limiting](#rate-limiting)
- [Logging and Debugging](#logging-and-debugging)

---

## Token Refresh Strategy

### Thread-Safe Token Service with Automatic Refresh

```swift
import Foundation
import WebPark

actor TokenService: WebParkTokenServiceProtocol {
    private var _token: String
    private var _refreshToken: String
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<Void, Error>] = []
    
    var token: String {
        _token
    }
    
    init(accessToken: String, refreshToken: String) {
        self._token = accessToken
        self._refreshToken = refreshToken
    }
    
    func refreshToken() async throws {
        // If already refreshing, wait for that to complete
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests.append(continuation)
            }
        }
        
        isRefreshing = true
        defer {
            isRefreshing = false
            // Resume all pending requests
            for continuation in pendingRequests {
                continuation.resume()
            }
            pendingRequests.removeAll()
        }
        
        // Perform the actual token refresh
        let url = URL(string: "https://api.example.com/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refreshToken": _refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TokenRefreshError.refreshFailed
        }
        
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        self._token = decoded.accessToken
        self._refreshToken = decoded.refreshToken
    }
}

enum TokenRefreshError: Error {
    case refreshFailed
    case invalidResponse
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
```

### API Client with Automatic Retry on 401

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol? = nil) {
        self.tokenService = tokenService
    }
}

extension APIClient {
    /// Performs a request with automatic token refresh on 401
    func requestWithRetry<T: Codable>(
        _ method: String,
        endpoint: String,
        body: (any Codable)? = nil
    ) async throws -> T {
        do {
            // First attempt
            return try await performRequest(method, endpoint: endpoint, body: body)
        } catch let error as WebParkHttpError where error.httpError == .unauthorized {
            // Got 401, refresh token and retry once
            try await tokenService?.refreshToken()
            return try await performRequest(method, endpoint: endpoint, body: body)
        }
    }
    
    private func performRequest<T: Codable>(
        _ method: String,
        endpoint: String,
        body: (any Codable)?
    ) async throws -> T {
        switch method {
        case "GET":
            return try await get(endpoint)
        case "POST":
            guard let body = body else {
                throw WebParkError.unableToMakeRequest
            }
            return try await post(endpoint, body: body as! any Codable)
        default:
            throw WebParkError.unableToMakeRequest
        }
    }
}
```

---

## Custom URLSession Configuration

### Timeout Configuration

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
    
    init(timeout: TimeInterval = 30) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
    }
}
```

### Custom Cache Policy

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
    
    init(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = cachePolicy
        
        // Configure cache
        let cache = URLCache(
            memoryCapacity: 50_000_000,    // 50 MB memory cache
            diskCapacity: 100_000_000      // 100 MB disk cache
        )
        config.urlCache = cache
        
        self.urlSession = URLSession(configuration: config)
    }
}
```

### Background Session for Long-Running Tasks

```swift
class APIClient: NSObject, WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
    
    override init() {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.myapp.background"
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        
        let session = URLSession(
            configuration: config,
            delegate: nil,
            delegateQueue: nil
        )
        
        self.urlSession = session
        super.init()
    }
}
```

---

## Error Recovery Patterns

### Exponential Backoff Retry

```swift
extension APIClient {
    func getWithRetry<T: Codable>(
        _ endpoint: String,
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelay
        
        while attempt < maxAttempts {
            do {
                return try await get(endpoint)
            } catch let error as WebParkHttpError {
                attempt += 1
                
                // Only retry on 5xx errors or rate limiting
                let shouldRetry = error.httpError == .internalServerError ||
                                 error.httpError == .serviceUnavailable ||
                                 error.httpError == .tooManyRequests
                
                guard shouldRetry && attempt < maxAttempts else {
                    throw error
                }
                
                // Exponential backoff
                try await Task.sleep(for: .seconds(delay))
                delay *= 2
            }
        }
        
        throw WebParkError.unableToMakeRequest
    }
}
```

### Graceful Degradation

```swift
extension APIClient {
    func getUsersWithFallback() async throws -> [User] {
        do {
            // Try primary endpoint
            return try await get("/users/v2")
        } catch let error as WebParkHttpError where error.httpError == .notFound {
            // Fall back to v1 endpoint
            return try await get("/users/v1")
        } catch {
            // Fall back to cached data
            return try loadCachedUsers()
        }
    }
    
    private func loadCachedUsers() throws -> [User] {
        // Load from local cache/database
        fatalError("Implement cache loading")
    }
}
```

### Circuit Breaker Pattern

```swift
actor CircuitBreaker {
    enum State {
        case closed      // Normal operation
        case open        // Failing, reject requests
        case halfOpen    // Testing if service recovered
    }
    
    private var state: State = .closed
    private var failureCount = 0
    private let failureThreshold = 5
    private let timeout: TimeInterval = 60.0
    private var lastFailureTime: Date?
    
    func canExecute() async -> Bool {
        switch state {
        case .closed:
            return true
        case .open:
            // Check if timeout has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= timeout {
                state = .halfOpen
                return true
            }
            return false
        case .halfOpen:
            return true
        }
    }
    
    func recordSuccess() async {
        failureCount = 0
        state = .closed
    }
    
    func recordFailure() async {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= failureThreshold {
            state = .open
        }
    }
}

extension APIClient {
    func getWithCircuitBreaker<T: Codable>(
        _ endpoint: String,
        circuitBreaker: CircuitBreaker
    ) async throws -> T {
        guard await circuitBreaker.canExecute() else {
            throw CircuitBreakerError.circuitOpen
        }
        
        do {
            let result: T = try await get(endpoint)
            await circuitBreaker.recordSuccess()
            return result
        } catch {
            await circuitBreaker.recordFailure()
            throw error
        }
    }
}

enum CircuitBreakerError: Error {
    case circuitOpen
}
```

---

## Testing Strategies

### Comprehensive Test Suite

```swift
import Testing
@testable import MyApp

@Suite("User API Tests")
struct UserAPITests {
    let mockSession: URLSession
    let api: APIClient
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        self.mockSession = URLSession(configuration: config)
        self.api = APIClient(urlSession: mockSession)
    }
    
    @Test("Get users success")
    func getUsersSuccess() async throws {
        let users = [
            User(id: 1, name: "Alice", email: "alice@example.com"),
            User(id: 2, name: "Bob", email: "bob@example.com")
        ]
        let data = try JSONEncoder().encode(users)
        let url = URL(string: "https://api.example.com/users")!
        
        URLProtocolMock.setMock((
            error: nil,
            data: data,
            response: HTTPURLResponse(url: url, statusCode: 200,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        let result: [User] = try await api.get("/users")
        
        #expect(result.count == 2)
        #expect(result[0].name == "Alice")
        #expect(result[1].name == "Bob")
    }
    
    @Test("Get users handles 500 error")
    func getUsersServerError() async throws {
        let url = URL(string: "https://api.example.com/users")!
        
        URLProtocolMock.setMock((
            error: nil,
            data: nil,
            response: HTTPURLResponse(url: url, statusCode: 500,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        do {
            let _: [User] = try await api.get("/users")
            Issue.record("Should have thrown error")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .internalServerError)
            #expect(error.statusCode == 500)
        }
    }
    
    @Test("Post user creates successfully")
    func postUserSuccess() async throws {
        let request = CreateUserRequest(name: "Charlie", email: "charlie@example.com")
        let response = User(id: 3, name: "Charlie", email: "charlie@example.com")
        let data = try JSONEncoder().encode(response)
        let url = URL(string: "https://api.example.com/users")!
        
        URLProtocolMock.setMock((
            error: nil,
            data: data,
            response: HTTPURLResponse(url: url, statusCode: 201,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        let result: User = try await api.post("/users", body: request)
        
        #expect(result.id == 3)
        #expect(result.name == "Charlie")
    }
}
```

### Testing with Token Service

```swift
@Suite("Authenticated API Tests")
struct AuthenticatedAPITests {
    
    @Test("Requests include bearer token")
    func requestsIncludeBearerToken() async throws {
        let tokenService = MockTokenService(token: "test-token-123")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let mockSession = URLSession(configuration: config)
        
        let api = APIClient(
            tokenService: tokenService,
            urlSession: mockSession
        )
        
        // Set up mock to capture the request
        let url = URL(string: "https://api.example.com/users")!
        let data = try JSONEncoder().encode([User]())
        
        URLProtocolMock.setMock((
            error: nil,
            data: data,
            response: HTTPURLResponse(url: url, statusCode: 200,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        let _: [User] = try await api.get("/users")
        
        // Verify token was included (would need to enhance URLProtocolMock to capture requests)
        #expect(tokenService.tokenWasAccessed)
    }
}

class MockTokenService: WebParkTokenServiceProtocol {
    var token: String
    var tokenWasAccessed = false
    var refreshCallCount = 0
    
    init(token: String) {
        self.token = token
    }
    
    func refreshToken() async throws {
        refreshCallCount += 1
        token = "refreshed-token-\(refreshCallCount)"
    }
}
```

---

## Performance Optimization

### Request Batching

```swift
extension APIClient {
    func batchGetUsers(ids: [Int]) async throws -> [User] {
        // Instead of N requests, make one with query parameters
        let idsString = ids.map { String($0) }.joined(separator: ",")
        let queryItems = [URLQueryItem(name: "ids", value: idsString)]
        return try await get("/users", queryItems: queryItems)
    }
}
```

### Concurrent Requests

```swift
extension APIClient {
    func getUsersAndProducts() async throws -> (users: [User], products: [Product]) {
        async let users: [User] = get("/users")
        async let products: [Product] = get("/products")
        
        return try await (users, products)
    }
    
    func getMultipleUsers(ids: [Int]) async throws -> [User] {
        try await withThrowingTaskGroup(of: User.self) { group in
            for id in ids {
                group.addTask {
                    try await self.get("/users/\(id)")
                }
            }
            
            var users: [User] = []
            for try await user in group {
                users.append(user)
            }
            return users
        }
    }
}
```

### Response Caching

```swift
actor ResponseCache<T: Codable> {
    private var cache: [String: CacheEntry<T>] = [:]
    private let maxAge: TimeInterval
    
    init(maxAge: TimeInterval = 300) { // 5 minutes default
        self.maxAge = maxAge
    }
    
    func get(_ key: String) -> T? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < maxAge else {
            return nil
        }
        return entry.value
    }
    
    func set(_ key: String, value: T) {
        cache[key] = CacheEntry(value: value, timestamp: Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}

struct CacheEntry<T> {
    let value: T
    let timestamp: Date
}

extension APIClient {
    private static let userCache = ResponseCache<[User]>()
    
    func getUsersCached() async throws -> [User] {
        let cacheKey = "users_list"
        
        // Check cache first
        if let cached = await Self.userCache.get(cacheKey) {
            return cached
        }
        
        // Fetch from network
        let users: [User] = try await get("/users")
        
        // Store in cache
        await Self.userCache.set(cacheKey, value: users)
        
        return users
    }
}
```

---

## Dependency Injection

### Protocol-Based Approach

```swift
protocol UserServiceProtocol {
    func getUsers() async throws -> [User]
    func getUser(id: Int) async throws -> User
    func createUser(_ request: CreateUserRequest) async throws -> User
}

struct UserService: UserServiceProtocol, WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    let urlSession: URLSession
    
    init(
        tokenService: WebParkTokenServiceProtocol? = nil,
        urlSession: URLSession = .shared
    ) {
        self.tokenService = tokenService
        self.urlSession = urlSession
    }
    
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func getUser(id: Int) async throws -> User {
        try await get("/users/\(id)")
    }
    
    func createUser(_ request: CreateUserRequest) async throws -> User {
        try await post("/users", body: request)
    }
}

// In your app
@MainActor
class UserViewModel: ObservableObject {
    private let userService: UserServiceProtocol
    @Published var users: [User] = []
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    func loadUsers() async {
        do {
            users = try await userService.getUsers()
        } catch {
            // Handle error
        }
    }
}
```

---

## Pagination

### Cursor-Based Pagination

```swift
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let cursor: String?
    let hasMore: Bool
}

extension APIClient {
    func getPaginatedUsers(cursor: String? = nil) async throws -> PaginatedResponse<User> {
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        return try await get("/users/paginated", queryItems: queryItems)
    }
    
    func getAllUsersPaginated() async throws -> [User] {
        var allUsers: [User] = []
        var cursor: String? = nil
        
        repeat {
            let response: PaginatedResponse<User> = try await getPaginatedUsers(cursor: cursor)
            allUsers.append(contentsOf: response.data)
            cursor = response.cursor
        } while cursor != nil
        
        return allUsers
    }
}
```

### Offset-Based Pagination

```swift
struct PagedResponse<T: Codable>: Codable {
    let data: [T]
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

extension APIClient {
    func getUsersPage(page: Int, pageSize: Int = 20) async throws -> PagedResponse<User> {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        return try await get("/users", queryItems: queryItems)
    }
}
```

---

## Rate Limiting

### Client-Side Rate Limiter

```swift
actor RateLimiter {
    private var requestTimes: [Date] = []
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    
    init(maxRequests: Int, per timeWindow: TimeInterval) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }
    
    func waitForPermission() async throws {
        // Remove old requests outside the time window
        let cutoff = Date().addingTimeInterval(-timeWindow)
        requestTimes.removeAll { $0 < cutoff }
        
        // If at limit, wait until we can proceed
        if requestTimes.count >= maxRequests {
            let oldestRequest = requestTimes.first!
            let waitTime = timeWindow - Date().timeIntervalSince(oldestRequest)
            if waitTime > 0 {
                try await Task.sleep(for: .seconds(waitTime))
            }
            requestTimes.removeFirst()
        }
        
        requestTimes.append(Date())
    }
}

extension APIClient {
    private static let rateLimiter = RateLimiter(maxRequests: 100, per: 60)
    
    func getRateLimited<T: Codable>(_ endpoint: String) async throws -> T {
        try await Self.rateLimiter.waitForPermission()
        return try await get(endpoint)
    }
}
```

---

## Logging and Debugging

### Request/Response Logger

```swift
actor NetworkLogger {
    func logRequest(_ request: URLRequest) {
        print("📤 \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }
    
    func logResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let httpResponse = response as? HTTPURLResponse {
            let emoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            print("\(emoji) \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "?")")
        }
        
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
        }
        
        if let error = error {
            print("Error: \(error)")
        }
    }
}

// Custom URLSession with logging
class LoggingURLSession: URLSession {
    private let logger = NetworkLogger()
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        await logger.logRequest(request)
        
        do {
            let (data, response) = try await super.data(for: request)
            await logger.logResponse(data, response, nil)
            return (data, response)
        } catch {
            await logger.logResponse(nil, nil, error)
            throw error
        }
    }
}
```

---

## See Also

- [API Reference](API-Reference.md) - Complete API documentation
- [Migration Guide](Migration-Guide.md) - Migrating from other libraries
- [README](../README.md) - Getting started guide
