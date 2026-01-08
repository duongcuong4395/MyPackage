# StateManagementKit

![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2013.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A modern, type-safe state management framework for SwiftUI that makes complex state handling simple and crash-free.

## 🌟 Features

- ✅ **Type-Safe Mutations** - Zero runtime crashes with compile-time safety
- 🔄 **Optimistic UI Updates** - Instant UI feedback with automatic rollback on failure
- ↩️ **Undo/Redo Support** - Built-in undo/redo with configurable history depth
- 📄 **Automatic Pagination** - Load more data with a single method call
- 🔁 **Smart Retry Logic** - Exponential backoff retry policies for network resilience
- 🎯 **Task Management** - Automatic cancellation prevents race conditions and memory leaks
- 🚀 **High Performance** - Lazy caching and minimal recomputation
- 🧪 **Testable** - Protocol-based design with mock support

## 📦 Installation

### Swift Package Manager

Add StateManagementKit to your project through Xcode:

```
File > Add Packages > Enter package URL
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/duongcuong4395/MyPackage.git", from: "2.0.0")
]
```

## 🚀 Quick Start

### Basic Usage

```swift
import StateManagementKit

// Define your model
struct User: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var email: String
}

// Create a store
class UserViewModel: ObservableObject {
    let store = StateStore<User>()
    
    func loadUsers() async {
        await store.loadPage { page, pageSize in
            try await api.fetchUsers(page: page, size: pageSize)
        }
    }
    
    func updateUserName(_ id: UUID, name: String) {
        // Optimistic update - UI responds immediately
        store.update(id, keyPath: \.name, value: name)
    }
    
    func saveChanges() {
        // Commit all pending mutations
        store.commitMutations()
    }
}
```

### SwiftUI Integration

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        List {
            switch viewModel.store.state {
            case .idle:
                Text("Loading...")
            case .loading(let previous):
                // Show previous data while loading
                userList(previous ?? [])
            case .success:
                userList(viewModel.store.allModels())
            case .failure(let error, let previous):
                ErrorView(error: error) {
                    Task { await viewModel.loadUsers() }
                }
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }
}
```

## 📚 Core Concepts

### AsyncState

Represents the state of asynchronous operations:

```swift
enum AsyncState<T> {
    case idle                                    // Initial state
    case loading(previous: T? = nil)             // Loading with optional previous data
    case success(T)                              // Success with data
    case failure(StateError, previous: T? = nil) // Error with optional previous data
}
```

### StateStore vs SingleStateStore

**StateStore**: For collections of identifiable items

```swift
let store = StateStore<Todo>()  // Manages [Todo]
store.update(todoId, keyPath: \.title, value: "New Title")
```

**SingleStateStore**: For single model instances

```swift
let store = SingleStateStore<UserProfile>()  // Manages UserProfile
store.update(keyPath: \.bio, value: "New bio")
```

### Optimistic Updates

Make UI changes immediately before server confirmation:

```swift
// 1. Update UI instantly (optimistic)
store.update(id, keyPath: \.isCompleted, value: true)

// 2. User sees immediate feedback

// 3. Commit when ready
store.commitMutations()

// 4. Sync with backend
try await api.save(store.allModels())
```

### Batch Updates

Update multiple properties atomically:

```swift
store.batchUpdate(userId) { builder in
    builder.set(\.name, to: "John Doe")
    builder.set(\.email, to: "john@example.com")
    builder.set(\.age, to: 30)
}
```

### Undo/Redo

```swift
// Enable undo/redo
store.enableUndoRedo()

// Make changes
store.update(id, keyPath: \.title, value: "New Title")

// Undo
store.undo()  // if store.canUndo

// Redo
store.redo()  // if store.canRedo
```

### Pagination

```swift
// Load first page
await store.loadPage(page: 0)

// Load next page (appends to existing data)
await store.loadNextPage { page, size in
    try await api.fetch(page: page, size: size)
}

// Check if more pages available
if store.hasMorePages {
    // Load more...
}
```

### Retry Policies

Handle transient failures automatically:

```swift
// Default retry policy (3 attempts, exponential backoff)
await store.loadPage(retryPolicy: .default) { page, size in
    try await api.fetch(page: page, size: size)
}

// Aggressive retry
await store.loadPage(retryPolicy: .aggressive) { page, size in
    try await api.fetch(page: page, size: size)
}

// Custom retry policy
let customPolicy = RetryPolicy(
    maxAttempts: 5,
    initialDelay: 0.5,
    maxDelay: 30.0,
    multiplier: 2.0
)
```

## ⚙️ Configuration

Customize state management behavior:

```swift
let config = StateConfiguration(
    debounceInterval: 0.05,  // Debounce for rapid updates
    maxUndoSteps: 50,        // Undo history depth
    enableLogging: true,     // Debug logging
    pageSize: 20             // Items per page
)

let store = StateStore<Item>(config: config)
```

## 🎯 Advanced Features

### Task Cancellation

Automatic task cancellation prevents race conditions:

```swift
// Load data with ID
await store.loadPage(page: 0)

// If called again, previous task is automatically cancelled
await store.loadPage(page: 1)  // Cancels previous load
```

### Error Handling

Type-safe error handling with context:

```swift
switch store.state {
case .failure(let error, let previousData):
    switch error {
    case .network(let message):
        print("Network error: \(message)")
    case .unauthorized:
        // Handle auth error
    case .notFound:
        // Handle 404
    default:
        print(error.localizedDescription)
    }
}
```

### Reactive Updates

Store publishes changes automatically:

```swift
class ViewModel: ObservableObject {
    @Published var store = StateStore<Item>()
    
    // SwiftUI views automatically update when:
    // - state changes
    // - mutations are applied
    // - undo/redo is performed
}
```

## 🧪 Testing

StateManagementKit is designed for easy testing:

```swift
class ViewModelTests: XCTestCase {
    func testOptimisticUpdate() async throws {
        let store = StateStore<Todo>()
        store.setState(.success([Todo(id: UUID(), title: "Test")]))
        
        let id = store.allModels().first!.id
        store.update(id, keyPath: \.title, value: "Updated")
        
        XCTAssertEqual(store.model(withId: id)?.title, "Updated")
        XCTAssertTrue(store.hasMutations(for: id))
    }
}
```

## 🏗️ Architecture

```
StateManagementKit
├── Core
│   ├── AsyncState          # State representation
│   ├── StateStore          # Collection store
│   └── SingleStateStore    # Single item store
├── Mutations
│   ├── TypeSafeMutation    # Type-safe transformations
│   └── UpdateBuilder       # Batch update builder
├── Tasks
│   ├── TaskManager         # Async task lifecycle
│   └── RetryPolicy         # Retry configuration
└── Utilities
    ├── CircularBuffer      # Memory-efficient undo/redo
    └── StateConfiguration  # Global configuration
```

## 📖 Best Practices

### 1. Always Use Type-Safe Updates

```swift
// ✅ Good - Compile-time safe
store.update(id, keyPath: \.title, value: "New Title")

// ❌ Bad - Runtime unsafe
// Manually manipulating data array
```

### 2. Commit or Discard Mutations

```swift
// After user confirmation
store.commitMutations()

// On cancel
store.discardMutations()
```

### 3. Handle All State Cases

```swift
switch store.state {
case .idle: /* Show empty state */
case .loading(let previous): /* Show loading + previous data */
case .success: /* Show data */
case .failure(let error, let previous): /* Show error + previous data */
}
```

### 4. Use Pagination for Large Lists

```swift
// Don't load all data at once
await store.loadPage(page: 0)

// Load more as user scrolls
if nearEndOfList && store.hasMorePages {
    await store.loadNextPage { page, size in
        try await api.fetch(page: page, size: size)
    }
}
```

## 🙋 Support

- 🐛 Issues: [GitHub Issues](https://github.com/duongcuong4395/MyPackage/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/duongcuong4395/MyPackage/discussions)

## 🎉 Acknowledgments

Built with ❤️ for the SwiftUI community.

---

**Made with Swift** 🚀
