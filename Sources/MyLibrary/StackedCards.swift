//
//  StackedCards.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/25.
//

import Foundation

import SwiftUI

@available(iOS 17.0, *)
extension Array where Element: Identifiable {
    public func zIndex(_ item: Element) -> CGFloat {
        if let index = firstIndex(where: { $0.id == item.id }) {
            return CGFloat(count) - CGFloat(index)
        }
        return .zero
    }
}

@available(iOS 17.0, *)
public struct StackedCardsView<Item: Identifiable, Content: View>: View {
    public var items: [Item]
    public let content: (Item) -> Content
    
    // State variables
    @State private var isRotationEnabled: Bool = true
    @State private var showsIndicator: Bool = false
    
    // Custom public initializer
    public init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    public var body: some View {
        VStack {
            GeometryReader { proxy in
                let size = proxy.size
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(items) { item in
                            content(item)
                                .padding(.horizontal, 10)
                                .frame(width: size.width)
                                .visualEffect { content, geometryProxy in
                                    let scaleValue = scale(proxy: geometryProxy, scale: 0.1)
                                    let rotationValue = rotation(proxy: geometryProxy, rotation: isRotationEnabled ? 5 : 0)
                                    let minXValue = minX(geometryProxy)
                                    let excessMinXValue = excessMinX(proxy: geometryProxy, offset: isRotationEnabled ? 8 : 10)
                                    
                                    content
                                        .scaleEffect(scaleValue, anchor: .trailing)
                                        .rotationEffect(rotationValue)
                                        .offset(x: minXValue)
                                        .offset(x: excessMinXValue)
                                }
                                .zIndex(items.zIndex(item))
                        }
                    }
                    .padding(.vertical, 15)
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(showsIndicator ? .visible : .hidden)
            }
        }
    }
    
    // MARK: - Helper Functions
    @MainActor
    private func minX(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        return minX < 0 ? 0 : -minX
    }

    @MainActor
    private func progress(_ proxy: GeometryProxy, limit: CGFloat = 2) -> CGFloat {
        let maxX = proxy.frame(in: .scrollView(axis: .horizontal)).maxX
        let width = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
        let progress = (maxX / width) - 1.0
        return min(progress, limit)
    }

    @MainActor
    private func scale(proxy: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
        let progress = progress(proxy)
        return 1 - (progress * scale)
    }

    @MainActor
    private func excessMinX(proxy: GeometryProxy, offset: CGFloat = 10) -> CGFloat {
        let progress = progress(proxy)
        return progress * offset
    }

    @MainActor
    private func rotation(proxy: GeometryProxy, rotation: CGFloat = 5) -> Angle {
        let progress = progress(proxy)
        return .degrees(progress * rotation)
    }
}

@available(iOS 17.0, *)
struct VisualEffectModifier: ViewModifier {
    let effect: (Content, GeometryProxy) -> AnyView

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            effect(content, proxy)
        }
    }
}

@available(iOS 17.0, *)
extension View {
    func visualEffect(
        @ViewBuilder effect: @escaping (Self, GeometryProxy) -> some View
    ) -> some View {
        self.modifier(VisualEffectModifier { content, proxy in
            AnyView(effect(content as! Self, proxy))
        })
    }
}
