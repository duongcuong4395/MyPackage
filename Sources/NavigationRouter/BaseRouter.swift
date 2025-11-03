//
//  BaseRouter.swift
//  MyLibrary
//
//  Created by Macbook on 28/10/25.
//

import SwiftUI
import Combine

// MARK: - Base Implementation
@available(iOS 16.0, *)
open class BaseRouter<Route: Hashable>: Router, ObservableObject {
    @Published public var path = NavigationPath()
    
    @Published private var routeStack: [Route] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentRoute: Route? {
        return routeStack.last
    }
    
    var currentRouteName: String {
        if let current = currentRoute {
            return String(describing: current)
        }
        return "Root"
    }
    
    public func isCurrentRoute(_ route: Route) -> Bool {
       return currentRoute == route
   }
   
   var routeHistory: [Route] {
       return routeStack
   }
   
   var navigationDepth: Int {
       return routeStack.count
   }
   
   var canPop: Bool {
       return !routeStack.isEmpty
   }
    
    
    public func push(_ route: Route) {
        path.append(route)
        routeStack.append(route)
    }
    
    public func pop() {
        if !path.isEmpty {
            path.removeLast()
            if !routeStack.isEmpty {
                routeStack.removeLast()
            }
        }
    }
    
    public func popToRoot() {
        path.removeLast(path.count)
        routeStack.removeAll()
    }
    
    public func replace(with route: Route) {
        if !path.isEmpty {
            path.removeLast()
            if !routeStack.isEmpty {
                routeStack.removeLast()
            }
        }
        path.append(route)
        routeStack.append(route)
    }
    
    // MARK: - Enhanced Navigation Methods
        
    /// Navigate to an existing route in stack or push if it doesn't exist
    /// - Parameter route: The route to navigate to
    /// - Returns: Bool indicating if route was found in stack (true) or pushed (false)
    @discardableResult
    public func navigateToOrPush(_ route: Route) -> Bool {
        if let existingIndex = routeStack.firstIndex(of: route) {
            // Route exists in stack, navigate to it
            navigateToExisting(at: existingIndex)
            return true
        } else {
            // Route doesn't exist, push it
            push(route)
            return false
        }
    }
    
    /// Navigate to a route at specific index in the route stack
    /// - Parameter index: The index of the route in routeStack
    private func navigateToExisting(at index: Int) {
        guard index < routeStack.count else { return }
        
        // Calculate how many routes to pop
        let routesToPop = routeStack.count - index - 1
        
        if routesToPop > 0 {
            // Pop from path
            path.removeLast(routesToPop)
            // Update routeStack
            routeStack.removeLast(routesToPop)
        }
    }
    
    /// Check if a route exists in the current route stack
    /// - Parameter route: The route to check
    /// - Returns: Bool indicating if route exists
    func containsRoute(_ route: Route) -> Bool {
        return routeStack.contains(route)
    }
    
    /// Get the index of a route in the route stack
    /// - Parameter route: The route to find
    /// - Returns: Optional index of the route
    func indexOfRoute(_ route: Route) -> Int? {
        return routeStack.firstIndex(of: route)
    }
    
    /// Navigate to a specific route if it exists in the stack
    /// - Parameter route: The route to navigate to
    /// - Returns: Bool indicating success
    @discardableResult
    func navigateToExistingRoute(_ route: Route) -> Bool {
        if let index = routeStack.firstIndex(of: route) {
            navigateToExisting(at: index)
            return true
        }
        return false
    }
    
    /// Pop to a specific route if it exists in the stack
    /// - Parameter route: The route to pop to
    /// - Returns: Bool indicating success
    @discardableResult
    func popTo(_ route: Route) -> Bool {
        return navigateToExistingRoute(route)
    }
    
    /// Push route only if it doesn't already exist in the stack
    /// - Parameter route: The route to push
    /// - Returns: Bool indicating if route was pushed (true) or already existed (false)
    @discardableResult
    func pushIfNotExists(_ route: Route) -> Bool {
        if !containsRoute(route) {
            push(route)
            return true
        }
        return false
    }
    
    /// Get routes from current position to root
    var routesToRoot: [Route] {
        return Array(routeStack.reversed())
    }
    
    /// Get routes from root to current position
    var routesFromRoot: [Route] {
        return routeStack
    }
    
    public init() {
        // Listen to path changes to sync routeStack
        setupPathObserver()
    }
    
    // MARK: - Path Synchronization
    private func setupPathObserver() {
        $path
            .dropFirst() // Skip initial value
            .sink { [weak self] newPath in
                self?.syncRouteStack(with: newPath)
            }
            .store(in: &cancellables)
    }
    
    private func syncRouteStack(with path: NavigationPath) {
        // If path count is less than routeStack, user used native back button
        let pathCount = path.count
        let stackCount = routeStack.count
        
        if pathCount < stackCount {
            // Remove the difference from routeStack
            let difference = stackCount - pathCount
            routeStack.removeLast(difference)
        }
        // Note: When pushing, we handle it in push() method
        // so we don't need to do anything here for additions
    }
}
