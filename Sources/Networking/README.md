# Networking Package

A modern, type-safe networking layer for iOS applications built on top of Alamofire with async/await support.

## Features

- ✅ **Type-Safe**: Protocol-oriented design with generic types
- 🚀 **Async/Await**: Modern Swift concurrency support
- 🎯 **Router Pattern**: Clean separation of endpoint definitions
- 🔄 **Automatic JSON Decoding**: Seamless conversion to Swift models
- ⚡ **Error Handling**: Comprehensive error management
- 🧪 **Testable**: Easy to mock and test
- 📦 **Lightweight**: Minimal dependencies (Alamofire only)

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+
- Alamofire 5.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Networking.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File > Add Packages...
2. Enter the repository URL
3. Select version/branch
4. Add to your target

## Architecture

The package consists of several key components:

```
┌─────────────────┐
│   APIExecution  │ ◄── Your Service Layer
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   APIRequest    │ ◄── Executes requests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   HttpRouter    │ ◄── Defines endpoints
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   APIResult     │ ◄── Wraps response
└─────────────────┘
```

## Quick Start

### 1. Define Your Models

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

struct UsersResponse: Codable {
    let users: [User]
    let total: Int
}
```

### 2. Create API Router

```swift
import Alamofire

enum UserAPI {
    case getUsers(page: Int)
    case getUserById(id: Int)
    case createUser(name: String, email: String)
    case updateUser(id: Int, name: String)
    case deleteUser(id: Int)
}

extension UserAPI: HttpRouter {
    typealias responseDataType = UsersResponse
    
    var baseURL: String {
        "https://api.example.com/v1"
    }
    
    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUserById(let id), .updateUser(let id, _), .deleteUser(let id):
            return "/users/\(id)"
        case .createUser:
            return "/users"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUsers, .getUserById:
            return .get
        case .createUser:
            return .post
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }
    
    var headers: HTTPHeaders? {
        ["Content-Type": "application/json"]
    }
    
    var parameters: Parameters? {
        switch self {
        case .getUsers(let page):
            return ["page": page, "limit": 20]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .createUser(let name, let email):
            let json = ["name": name, "email": email]
            return try? JSONSerialization.data(withJSONObject: json)
        case .updateUser(_, let name):
            let json = ["name": name]
            return try? JSONSerialization.data(withJSONObject: json)
        default:
            return nil
        }
    }
}
```

### 3. Create Service Layer

```swift
@available(iOS 13.0.0, *)
class UserService: APIExecution {
    
    func fetchUsers(page: Int = 1) async throws -> UsersResponse {
        try await sendRequest(for: UserAPI.getUsers(page: page))
    }
    
    func getUser(id: Int) async throws -> UsersResponse {
        try await sendRequest(for: UserAPI.getUserById(id: id))
    }
    
    func createUser(name: String, email: String) async throws -> UsersResponse {
        try await sendRequest(for: UserAPI.createUser(name: name, email: email))
    }
    
    func updateUser(id: Int, name: String) async throws -> UsersResponse {
        try await sendRequest(for: UserAPI.updateUser(id: id, name: name))
    }
    
    func deleteUser(id: Int) async throws -> UsersResponse {
        try await sendRequest(for: UserAPI.deleteUser(id: id))
    }
}
```

### 4. Use in Your App

```swift
@available(iOS 13.0.0, *)
class UserViewModel {
    private let userService = UserService()
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadUsers() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                let response = try await userService.fetchUsers()
                users = response.users
            } catch {
                errorMessage = handleError(error)
            }
            
            isLoading = false
        }
    }
    
    private func handleError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .DataFail:
                return "No data received from server"
            case .DecodingError:
                return "Failed to parse server response"
            case .requestError(let afError):
                return "Network error: \(afError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
}
```

## Advanced Usage

### Custom Response Handling

Override `handleResponse` for custom processing:

```swift
extension UserAPI {
    func handleResponse(with data: Data?, error: AFError?) -> APIResult<responseDataType> {
        // Custom validation
        if let err = error {
            print("API Error: \(err)")
            return .Failure(APIError.requestError(err))
        }
        
        guard let data = data else { 
            return .Failure(APIError.DataFail) 
        }
        
        // Custom decoding with date formatting
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(responseDataType.self, from: data)
            return .Successs(result)
        } catch {
            print("Decoding error: \(error)")
            return .Failure(APIError.DecodingError)
        }
    }
}
```

### Authentication Headers

Add authentication to your router:

```swift
extension UserAPI {
    var headers: HTTPHeaders? {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if let token = AuthManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
```

### Multipart File Upload

```swift
case uploadAvatar(userId: Int, imageData: Data)

var body: Data? {
    switch self {
    case .uploadAvatar(_, let imageData):
        return imageData
    default:
        return nil
    }
}

var headers: HTTPHeaders? {
    switch self {
    case .uploadAvatar:
        return ["Content-Type": "multipart/form-data"]
    default:
        return ["Content-Type": "application/json"]
    }
}
```

## Error Handling

The package provides three types of errors:

```swift
public enum APIError: Error {
    case DataFail          // No data received
    case DecodingError     // JSON parsing failed
    case requestError(AFError)  // Network/HTTP error
}
```

Handle errors in your UI:

```swift
do {
    let users = try await userService.fetchUsers()
    // Success
} catch APIError.DataFail {
    showAlert("No data received")
} catch APIError.DecodingError {
    showAlert("Invalid response format")
} catch APIError.requestError(let afError) {
    if afError.isResponseValidationError {
        showAlert("Invalid status code")
    } else if afError.isSessionTaskError {
        showAlert("Network connection failed")
    }
} catch {
    showAlert("Unknown error: \(error)")
}
```

## Testing

Mock your services for testing:

```swift
@available(iOS 13.0.0, *)
class MockUserService: APIExecution {
    var shouldFail = false
    var mockUsers: [User] = []
    
    func fetchUsers(page: Int) async throws -> UsersResponse {
        if shouldFail {
            throw APIError.DataFail
        }
        return UsersResponse(users: mockUsers, total: mockUsers.count)
    }
}

// In your tests
func testLoadUsers() async {
    let mockService = MockUserService()
    mockService.mockUsers = [
        User(id: 1, name: "Test", email: "test@test.com")
    ]
    
    let response = try await mockService.fetchUsers(page: 1)
    XCTAssertEqual(response.users.count, 1)
}
```

## Best Practices

1. **Separate Concerns**: Keep router definitions separate from business logic
2. **Error Handling**: Always handle all error cases
3. **Type Safety**: Use strong types for responses
4. **Reusability**: Create base routers for common configurations
5. **Testing**: Mock services for unit testing
6. **Documentation**: Document your API endpoints

## Common Patterns

### Base Router Protocol

```swift
protocol BaseRouter: HttpRouter {
    var baseURL: String { get }
    var headers: HTTPHeaders? { get }
}

extension BaseRouter {
    var baseURL: String {
        return "https://api.example.com/v1"
    }
    
    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}
```

### Paginated Responses

```swift
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let page: Int
    let totalPages: Int
    let total: Int
}

enum ProductAPI {
    case getProducts(page: Int)
}

extension ProductAPI: HttpRouter {
    typealias responseDataType = PaginatedResponse<Product>
    // ... implementation
}
```

## Troubleshooting

### Common Issues

**Q: Getting "DataFail" error**  
A: Check if your server is returning data. Add logging to verify response.

**Q: "DecodingError" occurs**  
A: Ensure your model matches the JSON structure. Use `JSONDecoder.KeyDecodingStrategy` if needed.

**Q: Request timeout**  
A: Configure Alamofire's session with custom timeout values.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- Your Name - [@yourusername](https://github.com/yourusername)

## Acknowledgments

- Built on top of [Alamofire](https://github.com/Alamofire/Alamofire)
- Inspired by modern Swift networking patterns
- Thanks to the Swift community

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

Made with ❤️ for the iOS community
