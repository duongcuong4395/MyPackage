//
//  NavigationRouter.swift
//  MyLibrary
//
//  Created by Macbook on 28/10/25.
//

import SwiftUI
import Combine

// MARK: - Generic Navigation Stack
@available(iOS 16.0, *)
public struct GenericNavigationStack<Route: Hashable, Content: View, Destination: View>: View {
    @ObservedObject var router: BaseRouter<Route>
    public let rootContent: () -> Content
    public let destination: (Route) -> Destination
    
    public init(router: BaseRouter<Route>, @ViewBuilder rootContent: @escaping () -> Content, @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.router = router
        self.rootContent = rootContent
        self.destination = destination
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            rootContent()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                        .environmentObject(router)
                }
        }
        .environmentObject(router)
    }
}

@available(iOS 16.0, *)
public struct NavigationRouter<Route: Hashable, Content: View, Destination: View>: View {
    @ObservedObject var router: BaseRouter<Route>
    public let rootContent: () -> Content
    public let destination: (Route) -> Destination
    
    public init(router: BaseRouter<Route>, @ViewBuilder rootContent: @escaping () -> Content, @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.router = router
        self.rootContent = rootContent
        self.destination = destination
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            rootContent()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                        .environmentObject(router)
                }
        }
        .environmentObject(router)
    }
}



