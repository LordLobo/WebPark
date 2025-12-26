# Quick Start Guide

Get up and running with WebPark in 5 minutes!

## Installation

### Swift Package Manager

Add WebPark to your project in Xcode:

1. **File → Add Package Dependencies**
2. Enter: `https://github.com/yourusername/WebPark.git`
3. Select version and add to your target

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/WebPark.git", from: "1.0.0")
]
```

## Your First API Call

### Step 1: Define Your Model

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}
```

### Step 2: Create Your API Client

```swift
import WebPark

struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
}
```

### Step 3: Add an Endpoint Method

```swift
extension MyAPI {
    func getUsers() async throws -> [User] {
        try await get("/users")
    }
}
```

### Step 4: Make the Call

```swift
let api = MyAPI()

Task {
    do {
        let users = try await api.getUsers()
        print("Found \(users.count) users")
        for user in users {
            print("- \(user.name)")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

## Complete Example App

Here's a complete working example with SwiftUI:

```swift
import SwiftUI
import WebPark

// MARK: - Models

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - API Client

struct GitHubAPI: WebPark {
    let baseURL = "https://api.github.com"
}

extension GitHubAPI {
    func searchUsers(query: String) async throws -> SearchResult {
        let queryItems = [URLQueryItem(name: "q", value: query)]
        return try await get("/search/users", queryItems: queryItems)
    }
}

struct SearchResult: Codable {
    let items: [GitHubUser]
}

struct GitHubUser: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, login
        case avatarUrl = "avatar_url"
    }
}

// MARK: - ViewModel

@MainActor
class UserSearchViewModel: ObservableObject {
    @Published var users: [GitHubUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = GitHubAPI()
    
    func search(query: String) async {
        guard !query.isEmpty else {
            users = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await api.searchUsers(query: query)
            users = result.items
        } catch let error as WebParkHttpError {
            errorMessage = "HTTP Error: \(error.description)"
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - View

struct ContentView: View {
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search GitHub users", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: searchText) { _, newValue in
                        Task {
                            await viewModel.search(query: newValue)
                        }
                    }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                List(viewModel.users) { user in
                    HStack {
                        AsyncImage(url: URL(string: user.avatarUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        Text(user.login)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("GitHub Search")
        }
    }
}

// MARK: - App

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Common Patterns

### POST Request with Body

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

extension MyAPI {
    func createUser(name: String, email: String) async throws -> User {
        let request = CreateUserRequest(name: name, email: email)
        return try await post("/users", body: request)
    }
}

// Usage
let newUser = try await api.createUser(name: "Alice", email: "alice@example.com")
```

### PUT Request to Update

```swift
extension MyAPI {
    func updateUser(id: Int, name: String, email: String) async throws -> User {
        let request = CreateUserRequest(name: name, email: email)
        return try await put("/users/\(id)", body: request)
    }
}

// Usage
let updated = try await api.updateUser(id: 42, name: "Bob", email: "bob@example.com")
```

### DELETE Request

```swift
extension MyAPI {
    func deleteUser(id: Int) async throws {
        try await delete("/users/\(id)")
    }
}

// Usage
try await api.deleteUser(id: 42)
```

### Query Parameters

```swift
extension MyAPI {
    func searchUsers(name: String, limit: Int = 20) async throws -> [User] {
        let queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        return try await get("/users/search", queryItems: queryItems)
    }
}

// Usage
let results = try await api.searchUsers(name: "Alice", limit: 10)
// Requests: /users/search?name=Alice&limit=10
```

## Adding Authentication

### Step 1: Create Token Service

```swift
actor TokenService: WebParkTokenServiceProtocol {
    private var _token: String
    
    var token: String {
        _token
    }
    
    init(token: String) {
        self._token = token
    }
    
    func refreshToken() async throws {
        // Call your refresh endpoint
        // Update self._token
    }
}
```

### Step 2: Add to API Client

```swift
struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: WebParkTokenServiceProtocol?
    
    init(tokenService: WebParkTokenServiceProtocol? = nil) {
        self.tokenService = tokenService
    }
}
```

### Step 3: Use It

```swift
let tokenService = TokenService(token: "your-access-token")
let api = MyAPI(tokenService: tokenService)

// All requests automatically include: Authorization: Bearer your-access-token
let users = try await api.getUsers()
```

## Error Handling

### Basic Error Handling

```swift
do {
    let users = try await api.getUsers()
    print("Success: \(users.count) users")
} catch {
    print("Error: \(error)")
}
```

### Detailed Error Handling

```swift
do {
    let user = try await api.getUser(id: 999)
    print("Found user: \(user.name)")
} catch let error as WebParkHttpError {
    // HTTP errors (4xx, 5xx)
    switch error.httpError {
    case .notFound:
        print("User not found")
    case .unauthorized:
        print("Need to log in")
    case .forbidden:
        print("Access denied")
    case .tooManyRequests:
        print("Rate limited, try again later")
    default:
        print("Server error: \(error.description)")
    }
} catch let error as WebParkError {
    // Library errors
    switch error {
    case .unableToMakeURL:
        print("Invalid URL")
    case .decodeFailure(let message):
        print("Failed to decode: \(message)")
    case .encodeFailure(let message):
        print("Failed to encode: \(message)")
    default:
        print("WebPark error: \(error)")
    }
} catch {
    // Other errors (network, etc.)
    print("Unexpected error: \(error)")
}
```

## Testing

### Simple Test Example

```swift
import Testing
@testable import MyApp

@Suite("API Tests")
struct APITests {
    
    func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
    
    @Test("Get users returns data")
    func getUsersSuccess() async throws {
        let mockSession = createMockSession()
        let api = MyAPI(urlSession: mockSession)
        
        // Setup mock
        let users = [User(id: 1, name: "Test", email: "test@example.com")]
        let data = try JSONEncoder().encode(users)
        let url = URL(string: "https://api.example.com/users")!
        
        URLProtocolMock.setMock((
            error: nil,
            data: data,
            response: HTTPURLResponse(url: url, statusCode: 200,
                                     httpVersion: nil, headerFields: nil)
        ), for: url)
        
        // Test
        let result = try await api.getUsers()
        
        #expect(result.count == 1)
        #expect(result[0].name == "Test")
    }
}
```

## Next Steps

Now that you have the basics, explore:

- **[Advanced Usage Guide](Advanced-Usage.md)** - Retry logic, caching, pagination
- **[API Reference](API-Reference.md)** - Complete API documentation
- **[Migration Guide](Migration-Guide.md)** - Coming from other libraries
- **[README](../README.md)** - Full documentation

## Common Issues

### Issue: "Cannot find 'get' in scope"

**Solution**: Make sure you've imported WebPark and your type conforms to the `WebPark` protocol:

```swift
import WebPark

struct MyAPI: WebPark {  // ← Don't forget this!
    let baseURL = "https://api.example.com"
}
```

### Issue: Decoding errors

**Solution**: Make sure your model matches the JSON structure exactly. Use `CodingKeys` if needed:

```swift
struct User: Codable {
    let id: Int
    let fullName: String  // JSON has "full_name"
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"  // Map JSON key
    }
}
```

### Issue: "Value of type 'MyAPI' has no member 'urlSession'"

**Solution**: The default implementation should work automatically. If you need a custom session:

```swift
struct MyAPI: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession  // Explicitly add property
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
}
```

## Getting Help

- 📖 Check the [full documentation](../README.md)
- 🐛 Report bugs on [GitHub Issues](https://github.com/yourusername/WebPark/issues)
- 💬 Ask questions in [Discussions](https://github.com/yourusername/WebPark/discussions)
- 📧 Email: dan.giralte@gmail.com

Happy coding! 🎉
