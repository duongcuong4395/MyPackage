//
//  RoutablePage.swift
//  MyLibrary
//
//  Created by Macbook on 23/1/25.
//



import SwiftUI

// MARK: RoutablePage
public protocol RoutablePage: Hashable, CaseIterable {
    var rawValue: String { get }
}

// MARK: GenericRoutePath
public struct GenericRoutePath<Page: RoutablePage>: Hashable {
    public var route: Page
    private let uniqueID = UUID() // Đảm bảo tính duy nhất mỗi lần khởi tạo
    
    public init(_ route: Page) {
        self.route = route
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }

    public static func == (lhs: GenericRoutePath<Page>, rhs: GenericRoutePath<Page>) -> Bool {
        lhs.route == rhs.route
    }
}

// MARK: GenericRouter
@available(iOS 15.0, *)
public class GenericRouter<Page: RoutablePage>: ObservableObject {
    @Published public var currentRoute: GenericRoutePath<Page> = GenericRoutePath(Page.allCases.first!)
    
    public var changeRoute: ((GenericRoutePath<Page>) -> Void)?
    public var backRoute: (() -> Void)?
    
    public init() {}
    
    public func navigate(to route: Page) {
        let newPath = GenericRoutePath(route)
        currentRoute = newPath
        changeRoute?(newPath)
    }
    
    public func back() {
        backRoute?()
    }
}

// MARK: RouterFactory
/// Quản lý các instance
@available(iOS 15.0, *)
public class RouterFactory {
    @MainActor private static var routers: [String: Any] = [:]
    
    @MainActor public static func sharedRouter<Page: RoutablePage>(for type: Page.Type) -> GenericRouter<Page> {
        let key = String(describing: type)
        if let router = routers[key] as? GenericRouter<Page> {
            return router
        } else {
            let newRouter = GenericRouter<Page>()
            routers[key] = newRouter
            return newRouter
        }
    }
}

/* Example:
 
// MARK: Apply module GenericRoutePath into other page
public enum ARCarPages: String, RoutablePage {
    case Catalog
    case Cars
    case ARCar
    case None
}


// Lấy router cho ARCarPages
var arCarRouter = RouterFactory.sharedRouter(for: ARCarPages.self)
arCarRouter.navigate(to: .ARCar)
 */
