# 🧭 NavigationRouter

A powerful, type-safe navigation system for SwiftUI that eliminates navigation spaghetti code and makes your app's navigation flow predictable, testable, and maintainable.

## 📋 Table of Contents

- [Why NavigationRouter?](#why-navigationrouter)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Testing](#testing)
- [Migration Guide](#migration-guide)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Why NavigationRouter?

### The Problem with Traditional SwiftUI Navigation

```swift
// ❌ Traditional Approach - Navigation Hell
struct ContentView: View {
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var selectedUserId: String?
    @State private var selectedTeamId: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Profile") { 
                    selectedUserId = "123"
                    showProfile = true 
                }
                
                NavigationLink(destination: ProfileView(...), isActive: $showProfile) {
                    EmptyView()
                }
                // ... more NavigationLinks
            }
        }
    }
}

// Problems:
// ❌ 2-3 @State variables per screen
// ❌ Navigation logic scattered everywhere
// ❌ Hard to test
// ❌ Not type-safe
// ❌ No navigation history tracking
// ❌ Deep linking is painful
```

### The NavigationRouter Solution

```swift
// ✅ NavigationRouter Approach - Clean & Simple
enum AppRoute: Hashable {
    case home
    case profile(userId: String)
    case settings
    case teamDetail(teamId: String)
}

struct ContentView: View {
    @StateObject private var router = AppRouter()
    
    var body: some View {
        GenericNavigationStack(router: router) {
            HomeView()
        } destination: { route in
            switch route {
            case .home: HomeView()
            case .profile(let userId): ProfileView(userId: userId)
            case .settings: SettingsView()
            case .teamDetail(let teamId): TeamDetailView(teamId: teamId)
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Button("Go to Profile") {
            router.push(.profile(userId: "123"))
        }
    }
}

// Benefits:
// ✅ Zero @State variables for navigation
// ✅ Centralized navigation logic
// ✅ 100% type-safe
// ✅ Easy to test
// ✅ Built-in history tracking
// ✅ Deep linking support out of the box
```

**Result: 70% less code, 100% more maintainable!**

---

## ✨ Features

### Core Features
- ✅ **Type-Safe Navigation** - Compile-time safety with enum-based routes
- ✅ **Zero @State Variables** - No more navigation state management in views
- ✅ **Centralized Logic** - All navigation logic in one place
- ✅ **History Tracking** - Built-in navigation stack tracking
- ✅ **Deep Linking Ready** - Easy to implement universal links

### Advanced Features
- 🚀 **Smart Navigation** - `navigateToOrPush()`, `popTo()`, `pushIfNotExists()`
- 🎯 **Route Querying** - Check current route, history, depth
- 🧪 **Testable** - Easy to mock and test navigation flows
- 📊 **Analytics Ready** - Track navigation events effortlessly
- 🔄 **SwiftUI Native** - Built on top of NavigationStack
- 🎨 **Flexible** - Works with any route enum you define

---

## 📦 Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15.0+

---

## 🚀 Installation

### Swift Package Manager

Add NavigationRouter to your project via Xcode:

1. File → Add Packages
2. Enter package URL: `https://github.com/yourusername/NavigationRouter.git`
3. Select version or branch
4. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NavigationRouter.git", from: "1.0.0")
]
```

### Manual Installation

1. Download the source files:
   - `Router.swift`
   - `BaseRouter.swift`
   - `GenericNavigationStack.swift`

2. Drag them into your Xcode project

---

## ⚡ Quick Start

### Step 1: Define Your Routes

```swift
import NavigationRouter

enum AppRoute: Hashable {
    case home
    case profile(userId: String)
    case settings
    case editProfile(userId: String)
    case teamDetail(teamId: String, section: String? = nil)
}
```

### Step 2: Create Your Router

```swift
class AppRouter: BaseRouter<AppRoute> {
    // That's it! BaseRouter handles everything
}
```

### Step 3: Setup Navigation

```swift
@main
struct MyApp: App {
    @StateObject private var router = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            NavigationRouter(router: router) {
                HomeView()
            } destination: { route in
                switch route {
                case .home:
                    HomeView()
                case .profile(let userId):
                    ProfileView(userId: userId)
                case .settings:
                    SettingsView()
                case .editProfile(let userId):
                    EditProfileView(userId: userId)
                case .teamDetail(let teamId, let section):
                    TeamDetailView(teamId: teamId, section: section)
                }
            }
        }
    }
}
```

### Step 4: Navigate!

```swift
struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack {
            Button("View Profile") {
                router.push(.profile(userId: "123"))
            }
            
            Button("Settings") {
                router.push(.settings)
            }
            
            Button("Back") {
                router.pop()
            }
            
            Button("Back to Home") {
                router.popToRoot()
            }
        }
        .navigationTitle("Home")
    }
}
```

**That's it! You're ready to go! 🎉**

---

## 🏗️ Core Components

### 1. Router Protocol

Defines the contract for all routers.

```swift
protocol Router: ObservableObject {
    associatedtype Route: Hashable
    var path: NavigationPath { get set }
    
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func replace(with route: Route)
}
```

### 2. BaseRouter

The brain of the navigation system. Provides all navigation functionality.

```swift
class BaseRouter<Route: Hashable>: Router, ObservableObject {
    @Published var path = NavigationPath()
    @Published private var routeStack: [Route] = []
    
    // State Properties
    var currentRoute: Route?
    var currentRouteName: String
    var navigationDepth: Int
    var canPop: Bool
    var routeHistory: [Route]
    
    // Navigation Methods
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func replace(with route: Route)
    
    // Advanced Methods
    func navigateToOrPush(_ route: Route) -> Bool
    func popTo(_ route: Route) -> Bool
    func pushIfNotExists(_ route: Route) -> Bool
    func containsRoute(_ route: Route) -> Bool
    func isCurrentRoute(_ route: Route) -> Bool
}
```

### 3. GenericNavigationStack

SwiftUI wrapper that connects your router to NavigationStack.

```swift
struct NavigationRouter<Route, Content, Destination>: View 
    where Route: Hashable, Content: View, Destination: View {
    
    @ObservedObject var router: BaseRouter<Route>
    let rootContent: () -> Content
    let destination: (Route) -> Destination
}
```

---

## 📖 Basic Usage

### Navigation Methods

```swift
// Push a new route
router.push(.profile(userId: "123"))

// Pop back one level
router.pop()

// Pop to root
router.popToRoot()

// Replace current route
router.replace(with: .settings)
```

### Checking Current State

```swift
// Get current route
if let current = router.currentRoute {
    print("Current: \(current)")
}

// Get route name as string
print(router.currentRouteName) // "profile"

// Check if specific route is current
if router.isCurrentRoute(.home) {
    print("We're on home!")
}

// Get navigation depth
print("Depth: \(router.navigationDepth)") // 3

// Check if can pop
if router.canPop {
    router.pop()
}

// Get full route history
print(router.routeHistory) // [.home, .profile, .settings]
```

---

## 🚀 Advanced Features

### 1. Smart Navigation

#### Navigate to Existing or Push New

```swift
// If route exists in stack, navigate to it
// Otherwise, push it
let wasExisting = router.navigateToOrPush(.profile(userId: "123"))

if wasExisting {
    print("Navigated to existing route")
} else {
    print("Pushed new route")
}
```

#### Pop to Specific Route

```swift
// Pop back to a specific route in the stack
if router.popTo(.home) {
    print("Popped back to home")
} else {
    print("Home not in stack")
}
```

#### Push Only If Not Exists

```swift
// Prevents duplicate routes in stack
let wasPushed = router.pushIfNotExists(.settings)

if wasPushed {
    print("Settings pushed")
} else {
    print("Settings already in stack")
}
```

### 2. Route Querying

```swift
// Check if route exists in stack
if router.containsRoute(.profile(userId: "123")) {
    print("Profile is in the stack")
}

// Get index of route
if let index = router.indexOfRoute(.settings) {
    print("Settings is at index \(index)")
}

// Get routes from root to current
let routesFromRoot = router.routesFromRoot
// [.home, .profile, .editProfile]

// Get routes from current to root
let routesToRoot = router.routesToRoot
// [.editProfile, .profile, .home]
```

### 3. Deep Linking

```swift
class AppRouter: BaseRouter<AppRoute> {
    func handle(deepLink url: URL) {
        // Parse URL: myapp://profile/123/edit
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        let pathComponents = components.path.split(separator: "/")
        
        // Clear current stack
        popToRoot()
        
        // Build navigation stack
        if pathComponents.first == "profile" {
            if let userId = pathComponents.dropFirst().first {
                push(.profile(userId: String(userId)))
                
                if pathComponents.contains("edit") {
                    push(.editProfile(userId: String(userId)))
                }
            }
        }
    }
}

// Usage
router.handle(deepLink: URL(string: "myapp://profile/123/edit")!)
```

### 4. Conditional Navigation

```swift
struct CheckoutButton: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Button("Checkout") {
            if authService.isLoggedIn {
                router.push(.checkout)
            } else {
                // Navigate to login, then checkout
                router.push(.login(returnRoute: .checkout))
            }
        }
    }
}

// In LoginView after successful login
if let returnRoute = returnRoute {
    router.replace(with: returnRoute)
}
```

### 5. Navigation Guards

```swift
class AuthRouter: BaseRouter<AppRoute> {
    var authService: AuthService
    
    override func push(_ route: AppRoute) {
        // Guard protected routes
        switch route {
        case .profile, .settings, .editProfile:
            guard authService.isLoggedIn else {
                push(.login(returnRoute: route))
                return
            }
        default:
            break
        }
        
        super.push(route)
    }
}
```

### 6. Navigation Analytics

```swift
class AnalyticsRouter: BaseRouter<AppRoute> {
    private let analytics: AnalyticsService
    
    override func push(_ route: Route) {
        super.push(route)
        
        analytics.track(event: "screen_view", parameters: [
            "screen_name": String(describing: route),
            "navigation_depth": navigationDepth,
            "previous_screen": routeHistory.dropLast().last.map { String(describing: $0) } ?? "none"
        ])
    }
    
    override func pop() {
        let from = currentRouteName
        super.pop()
        
        analytics.track(event: "screen_back", parameters: [
            "from_screen": from,
            "to_screen": currentRouteName
        ])
    }
}
```

### 7. Tab-Based Navigation

```swift
struct MainTabView: View {
    @StateObject private var homeRouter = BaseRouter<HomeRoute>()
    @StateObject private var searchRouter = BaseRouter<SearchRoute>()
    @StateObject private var profileRouter = BaseRouter<ProfileRoute>()
    
    var body: some View {
        TabView {
            GenericNavigationStack(router: homeRouter) {
                HomeView()
            } destination: { route in
                // Home destinations
            }
            .tabItem { Label("Home", systemImage: "house") }
            
            GenericNavigationStack(router: searchRouter) {
                SearchView()
            } destination: { route in
                // Search destinations
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            
            GenericNavigationStack(router: profileRouter) {
                ProfileView()
            } destination: { route in
                // Profile destinations
            }
            .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

---

## 💡 Best Practices

### 1. Route Organization

```swift
// ✅ GOOD: Organized by feature
enum AppRoute: Hashable {
    // Authentication
    case login
    case register
    case forgotPassword
    
    // Home
    case home
    case feed
    
    // Profile
    case profile(userId: String)
    case editProfile(userId: String)
    case followers(userId: String)
    
    // Settings
    case settings
    case settingsAccount
    case settingsPrivacy
}

// ❌ BAD: Flat, unorganized
enum AppRoute: Hashable {
    case screen1
    case screen2
    case screenWithData(String)
}
```

### 2. Router Injection

```swift
// ✅ GOOD: Use @EnvironmentObject
struct ProfileView: View {
    @EnvironmentObject var router: AppRouter
    let userId: String
}

// ❌ BAD: Create new router
struct ProfileView: View {
    @StateObject var router = AppRouter() // Wrong!
}
```

### 3. Route Parameters

```swift
// ✅ GOOD: Explicit, type-safe parameters
case teamDetail(teamId: String, section: TeamSection?)
case userProfile(userId: String, tab: ProfileTab = .posts)

enum TeamSection: String, Hashable {
    case overview, roster, stats
}

// ❌ BAD: Generic, unclear parameters
case detail(String, Int?)
```

### 4. Route Naming

```swift
// ✅ GOOD: Clear, descriptive names
case userProfile(userId: String)
case editUserProfile(userId: String)
case teamRoster(teamId: String)

// ❌ BAD: Vague names
case detail(String)
case screen(id: String)
```

---

## 📚 Examples

### Example 1: E-Commerce App

```swift
enum ShopRoute: Hashable {
    case home
    case category(id: String)
    case product(id: String)
    case cart
    case checkout
    case orderConfirmation(orderId: String)
}

class ShopRouter: BaseRouter<ShopRoute> {}

struct ProductDetailView: View {
    @EnvironmentObject var router: ShopRouter
    let productId: String
    
    var body: some View {
        VStack {
            // Product details
            
            Button("Add to Cart") {
                addToCart()
                router.push(.cart)
            }
            
            Button("Buy Now") {
                addToCart()
                router.push(.checkout)
            }
        }
    }
}
```

### Example 2: Social Media App

```swift
enum SocialRoute: Hashable {
    case feed
    case post(id: String)
    case comments(postId: String)
    case userProfile(userId: String)
    case followers(userId: String)
    case editPost(postId: String)
    case createPost
}

struct PostView: View {
    @EnvironmentObject var router: BaseRouter<SocialRoute>
    let postId: String
    
    var body: some View {
        VStack {
            // Post content
            
            Button("View Comments") {
                router.push(.comments(postId: postId))
            }
            
            Button("View Author") {
                router.push(.userProfile(userId: post.authorId))
            }
            
            if post.isOwnPost {
                Button("Edit") {
                    router.push(.editPost(postId: postId))
                }
            }
        }
    }
}
```

### Example 3: Multi-Step Form

```swift
enum OnboardingRoute: Hashable {
    case welcome
    case step1PersonalInfo
    case step2Preferences
    case step3Verification
    case completed
}

class OnboardingRouter: BaseRouter<OnboardingRoute> {
    func nextStep() {
        switch currentRoute {
        case .welcome:
            push(.step1PersonalInfo)
        case .step1PersonalInfo:
            push(.step2Preferences)
        case .step2Preferences:
            push(.step3Verification)
        case .step3Verification:
            push(.completed)
        default:
            break
        }
    }
    
    func previousStep() {
        pop()
    }
    
    var canGoNext: Bool {
        currentRoute != .completed
    }
    
    var canGoBack: Bool {
        canPop && currentRoute != .welcome
    }
}
```

---

## 🧪 Testing

### Testing Navigation Logic

```swift
import XCTest
@testable import YourApp

class NavigationRouterTests: XCTestCase {
    var router: BaseRouter<AppRoute>!
    
    override func setUp() {
        super.setUp()
        router = BaseRouter<AppRoute>()
    }
    
    func testPushRoute() {
        router.push(.home)
        
        XCTAssertEqual(router.currentRoute, .home)
        XCTAssertEqual(router.navigationDepth, 1)
    }
    
    func testPopRoute() {
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.pop()
        
        XCTAssertEqual(router.currentRoute, .home)
        XCTAssertEqual(router.navigationDepth, 1)
    }
    
    func testPopToRoot() {
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        router.popToRoot()
        
        XCTAssertNil(router.currentRoute)
        XCTAssertEqual(router.navigationDepth, 0)
    }
    
    func testNavigateToExisting() {
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        
        let wasExisting = router.navigateToOrPush(.profile(userId: "123"))
        
        XCTAssertTrue(wasExisting)
        XCTAssertEqual(router.currentRoute, .profile(userId: "123"))
        XCTAssertEqual(router.navigationDepth, 2)
    }
    
    func testRouteHistory() {
        router.push(.home)
        router.push(.profile(userId: "123"))
        router.push(.settings)
        
        XCTAssertEqual(router.routeHistory, [
            .home,
            .profile(userId: "123"),
            .settings
        ])
    }
}
```

### Testing with Mock Router

```swift
class MockRouter: BaseRouter<AppRoute> {
    var pushedRoutes: [AppRoute] = []
    var popCount = 0
    
    override func push(_ route: AppRoute) {
        pushedRoutes.append(route)
        super.push(route)
    }
    
    override func pop() {
        popCount += 1
        super.pop()
    }
}

class ViewModelTests: XCTestCase {
    func testNavigationToProfile() {
        let router = MockRouter()
        let viewModel = HomeViewModel(router: router)
        
        viewModel.navigateToProfile(userId: "123")
        
        XCTAssertEqual(router.pushedRoutes.last, .profile(userId: "123"))
    }
}
```

---

## 🔄 Migration Guide

### From Traditional NavigationLink

**Before:**
```swift
struct OldView: View {
    @State private var showDetail = false
    @State private var selectedId: String?
    
    var body: some View {
        NavigationStack {
            Button("Show Detail") {
                selectedId = "123"
                showDetail = true
            }
            .navigationDestination(isPresented: $showDetail) {
                if let id = selectedId {
                    DetailView(id: id)
                }
            }
        }
    }
}
```

**After:**
```swift
struct NewView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Button("Show Detail") {
            router.push(.detail(id: "123"))
        }
    }
}
```

### Migration Steps

1. **Define Routes**
```swift
enum AppRoute: Hashable {
    // Map your existing screens
    case oldScreen1
    case oldScreen2(id: String)
}
```

2. **Create Router**
```swift
class AppRouter: BaseRouter<AppRoute> {}
```

3. **Replace NavigationStack**
```swift
// Old
NavigationStack {
    RootView()
}

// New
GenericNavigationStack(router: router) {
    RootView()
} destination: { route in
    // Map routes to views
}
```

4. **Replace NavigationLinks**
```swift
// Old
@State private var showDetail = false
NavigationLink(destination: DetailView(), isActive: $showDetail)

// New
@EnvironmentObject var router: AppRouter
router.push(.detail)
```

5. **Remove @State Variables**
```swift
// Delete these:
@State private var showDetail = false
@State private var showSettings = false
@State private var selectedId: String?
```

---

## ❓ FAQ

### Q: Can I use this with UIKit?
**A:** This package is designed for SwiftUI. For UIKit, consider using the Coordinator pattern.

### Q: Does it work with iPad split view?
**A:** Yes! It works with any SwiftUI navigation structure.

### Q: Can I have multiple routers?
**A:** Yes! Use one router per navigation stack (e.g., one per tab).

### Q: How do I handle modal presentations?
**A:** Use SwiftUI's `.sheet()` modifier alongside the router for push navigation.

```swift
struct ContentView: View {
    @StateObject var router = AppRouter()
    @State private var showModal = false
    
    var body: some View {
        GenericNavigationStack(router: router) {
            HomeView()
        } destination: { route in
            // Push destinations
        }
        .sheet(isPresented: $showModal) {
            // Modal content
        }
    }
}
```

### Q: Can I use it with SwiftData?
**A:** Yes! Pass your model IDs in routes, not the models themselves.

```swift
enum AppRoute: Hashable {
    case itemDetail(itemId: String) // ✅ Good
    // case itemDetail(item: Item)  // ❌ Bad - not Hashable
}
```

### Q: How do I handle navigation permissions?
**A:** Override the push method in your router:

```swift
class AuthRouter: BaseRouter<AppRoute> {
    var isAuthenticated: Bool = false
    
    override func push(_ route: AppRoute) {
        if route.requiresAuth && !isAuthenticated {
            super.push(.login)
            return
        }
        super.push(route)
    }
}
```
