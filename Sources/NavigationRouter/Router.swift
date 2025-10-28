//
//  Router.swift
//  MyLibrary
//
//  Created by Macbook on 28/10/25.
//

import Foundation
import SwiftUI

@available(iOS 16.0, *)
public protocol Router: ObservableObject {
    associatedtype Route: Hashable
    var path: NavigationPath { get set }
    
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func replace(with route: Route)
}



