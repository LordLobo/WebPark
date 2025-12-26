# Migration Guide

This guide helps you migrate to WebPark from other networking solutions.

## Table of Contents

- [From URLSession](#from-urlsession)
- [From Alamofire](#from-alamofire)
- [From Moya](#from-moya)
- [From Custom Networking Layer](#from-custom-networking-layer)
- [Version Migration](#version-migration)

---

## From URLSession

If you're using raw `URLSession`, WebPark significantly reduces boilerplate while maintaining type safety.

### Before: URLSession

```swift
struct APIClient {
    let baseURL = "https://api.example.com"
    let session = URLSession.shared
    
    func getUsers() async throws -> [User] {
        // Build URL
        guard let url = URL(string: baseURL + "/users") else {
            throw URLError(.badURL)
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authorization if needed
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Check status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        return try decoder.decode([User].self, from: data)
    }
    
    func createUser(_ user: CreateUserRequest) async throws -> User {
        guard let url = URL(string: baseURL + "/users") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(user)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(User.self, from: data)
    }
}
```

### After: WebPark

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol? = nil) {
        self.tokenService = tokenService
    }
}

extension APIClient {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func createUser(_ user: CreateUserRequest) async throws -> User {
        try await post("/users", body: user)
    }
}
```

### Benefits

✅ **90% less code**  
✅ **Automatic token injection**  
✅ **Built-in error handling**  
✅ **Type-safe with generics**  
✅ **Automatic JSON encoding/decoding**  

---

## From Alamofire

Alamofire is a popular networking library with many features. Here's how to transition to WebPark's simpler approach.

### Before: Alamofire

```swift
import Alamofire

class APIClient {
    let baseURL = "https://api.example.com"
    var authToken: String?
    
    func getUsers() async throws -> [User] {
        return try await AF.request(
            baseURL + "/users",
            method: .get,
            headers: authToken.map { ["Authorization": "Bearer \($0)"] }
        )
        .validate()
        .serializingDecodable([User].self)
        .value
    }
    
    func createUser(_ user: CreateUserRequest) async throws -> User {
        return try await AF.request(
            baseURL + "/users",
            method: .post,
            parameters: user,
            encoder: JSONParameterEncoder.default,
            headers: authToken.map { ["Authorization": "Bearer \($0)"] }
        )
        .validate()
        .serializingDecodable(User.self)
        .value
    }
    
    func uploadFile(_ fileURL: URL) async throws -> UploadResponse {
        return try await AF.upload(
            multipartFormData: { formData in
                formData.append(fileURL, withName: "file")
            },
            to: baseURL + "/upload",
            headers: authToken.map { ["Authorization": "Bearer \($0)"] }
        )
        .validate()
        .serializingDecodable(UploadResponse.self)
        .value
    }
}
```

### After: WebPark

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol? = nil) {
        self.tokenService = tokenService
    }
}

extension APIClient {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func createUser(_ user: CreateUserRequest) async throws -> User {
        try await post("/users", body: user)
    }
    
    // For file uploads, use URLSession directly or wait for WebPark multipart support
    func uploadFile(_ fileURL: URL) async throws -> UploadResponse {
        // Custom implementation using URLSession upload task
        // Multipart form data support coming in future WebPark version
        fatalError("Implement using URLSession.upload(for:from:)")
    }
}
```

### Migration Notes

| Alamofire Feature | WebPark Equivalent | Notes |
|-------------------|-------------------|-------|
| `.request()` | `get()`, `post()`, etc. | Simplified method-specific functions |
| `.validate()` | Automatic | Built-in status code validation |
| `.serializingDecodable()` | Generic return type | Automatic with Codable |
| `SessionManager` | `urlSession` property | Use custom URLSession if needed |
| `RequestInterceptor` | `WebParkTokenServiceProtocol` | For auth token handling |
| `MultipartFormData` | Not yet supported | Coming in future version |
| Network reachability | Not included | Use `Network` framework directly |
| Request/response logging | Not yet supported | Coming in future version |

### Missing Features (Future Roadmap)

WebPark is intentionally minimal. For these Alamofire features, you may need to:

- **Multipart uploads**: Use URLSession directly or wait for future WebPark support
- **Download tasks with progress**: Use URLSession download tasks
- **Request retrying**: Implement manually or wait for future support
- **Network reachability**: Use Apple's `Network` framework
- **Certificate pinning**: Configure URLSession directly

---

## From Moya

Moya uses a provider pattern with target types. WebPark uses a simpler protocol-based approach.

### Before: Moya

```swift
import Moya

enum UserAPI {
    case getUsers
    case getUser(id: Int)
    case createUser(CreateUserRequest)
    case updateUser(id: Int, CreateUserRequest)
    case deleteUser(id: Int)
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    
    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUser(let id):
            return "/users/\(id)"
        case .createUser:
            return "/users"
        case .updateUser(let id, _):
            return "/users/\(id)"
        case .deleteUser(let id):
            return "/users/\(id)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getUsers, .getUser:
            return .get
        case .createUser:
            return .post
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }
    
    var task: Task {
        switch self {
        case .getUsers, .getUser, .deleteUser:
            return .requestPlain
        case .createUser(let request), .updateUser(_, let request):
            return .requestJSONEncodable(request)
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}

class APIClient {
    let provider = MoyaProvider<UserAPI>()
    
    func getUsers() async throws -> [User] {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(.getUsers) { result in
                switch result {
                case .success(let response):
                    do {
                        let users = try response.map([User].self)
                        continuation.resume(returning: users)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

### After: WebPark

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
}

extension APIClient {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func getUser(id: Int) async throws -> User {
        try await get("/users/\(id)")
    }
    
    func createUser(_ request: CreateUserRequest) async throws -> User {
        try await post("/users", body: request)
    }
    
    func updateUser(id: Int, _ request: CreateUserRequest) async throws -> User {
        try await put("/users/\(id)", body: request)
    }
    
    func deleteUser(id: Int) async throws {
        try await delete("/users/\(id)")
    }
}
```

### Migration Benefits

✅ **Much simpler**: No need for TargetType enum  
✅ **Native async/await**: No continuation wrappers  
✅ **Less boilerplate**: No task/method/headers configuration  
✅ **Type-safe**: Same compile-time safety with less code  
✅ **Easier to read**: Direct method calls instead of enum cases  

### Moya Plugins → WebPark

| Moya Plugin | WebPark Approach |
|-------------|------------------|
| `AccessTokenPlugin` | `WebParkTokenServiceProtocol` |
| `NetworkLoggerPlugin` | Custom URLSession configuration (future: built-in logging) |
| `CredentialsPlugin` | Custom URLRequest modification |
| Custom plugins | Extend URLRequest or create middleware |

---

## From Custom Networking Layer

If you've built your own networking layer, migration depends on your architecture.

### Common Pattern: NetworkManager + APIEndpoint

**Before:**

```swift
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
}

class NetworkManager {
    let baseURL: String
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Build URL, request, perform call, decode...
    }
}

struct GetUsersEndpoint: APIEndpoint {
    let path = "/users"
    let method = .get
    let headers: [String: String]? = nil
}

// Usage
let manager = NetworkManager(baseURL: "https://api.example.com")
let users: [User] = try await manager.request(GetUsersEndpoint())
```

**After:**

```swift
struct APIClient: WebPark {
    let baseURL = "https://api.example.com"
}

extension APIClient {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
}

// Usage
let api = APIClient()
let users = try await api.getUsers()
```

### Common Pattern: Service Layer

**Before:**

```swift
protocol UserServiceProtocol {
    func getUsers() async throws -> [User]
    func createUser(_ request: CreateUserRequest) async throws -> User
}

class UserService: UserServiceProtocol {
    let networkManager: NetworkManager
    
    func getUsers() async throws -> [User] {
        try await networkManager.get("/users")
    }
    
    func createUser(_ request: CreateUserRequest) async throws -> User {
        try await networkManager.post("/users", body: request)
    }
}
```

**After:**

```swift
protocol UserServiceProtocol {
    func getUsers() async throws -> [User]
    func createUser(_ request: CreateUserRequest) async throws -> User
}

struct UserService: UserServiceProtocol, WebPark {
    let baseURL = "https://api.example.com"
    
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
    
    func createUser(_ request: CreateUserRequest) async throws -> User {
        try await post("/users", body: request)
    }
}
```

WebPark can serve as both the protocol and implementation!

---

## Version Migration

### Migrating to 1.0 (When Released)

Currently, WebPark is in active development. When 1.0 is released, breaking changes will be documented here.

### Expected Breaking Changes

Future versions may include:

- **Token service changes**: Consolidation of sync/async token protocols
- **Error handling improvements**: More detailed error types
- **Response metadata**: Access to headers and status codes
- **Request customization**: More options for timeouts, cache policy, etc.

---

## Migration Checklist

Use this checklist when migrating to WebPark:

- [ ] **Install WebPark** via Swift Package Manager
- [ ] **Create protocol conformance** (`MyAPI: WebPark`)
- [ ] **Set base URL** in your API struct
- [ ] **Migrate GET requests** to use `get()` method
- [ ] **Migrate POST requests** to use `post()` method
- [ ] **Migrate PUT requests** to use `put()` method
- [ ] **Migrate PATCH requests** to use `patch()` method
- [ ] **Migrate DELETE requests** to use `delete()` method
- [ ] **Implement token service** if using authentication
- [ ] **Update error handling** to use `WebParkError` and `WebParkHttpError`
- [ ] **Update tests** to use `URLProtocolMock`
- [ ] **Remove old networking code** and dependencies
- [ ] **Update documentation** in your project

---

## Getting Help

If you encounter issues during migration:

- Check the [API Reference](API-Reference.md) for detailed documentation
- Review [examples in the README](../README.md)
- Open a [GitHub Discussion](https://github.com/yourusername/WebPark/discussions)
- Report bugs via [GitHub Issues](https://github.com/yourusername/WebPark/issues)
- Email: dan.giralte@gmail.com

---

## Why Migrate to WebPark?

**For URLSession users:**
- ✨ 90% less boilerplate code
- 🔒 Type-safe with generics
- 🎯 Consistent error handling

**For Alamofire users:**
- 📦 Zero dependencies (lighter binary)
- ⚡️ Simpler API surface
- 🎯 Designed for Swift Concurrency from day one

**For Moya users:**
- 🚀 Less ceremony, more productivity
- 📖 Easier to understand and debug
- ✨ Still type-safe and testable

**For everyone:**
- 🌟 Modern Swift 6 features
- 🧪 Built-in testing utilities
- 📱 First-class Apple platform support
