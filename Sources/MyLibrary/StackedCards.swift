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
                                .applyCardEffects(proxy: proxy, isRotationEnabled: isRotationEnabled) // Áp dụng hiệu ứng
                                .zIndex(items.zIndex(item)) // Xác định thứ tự hiển thị
                        }
                    }
                    .padding(.vertical, 15)
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(showsIndicator ? .visible : .hidden)
            }
        }
    }
}

@available(iOS 17.0, *)
extension View {
    /// Áp dụng các hiệu ứng như scale, rotation, và offset.
    func applyCardEffects(proxy: GeometryProxy, isRotationEnabled: Bool) -> some View {
        let scaleValue = scale(proxy: proxy, scale: 0.1)
        let rotationValue = rotation(proxy: proxy, rotation: isRotationEnabled ? 5 : 0)
        let minXValue = minX(proxy)
        let excessMinXValue = excessMinX(proxy: proxy, offset: isRotationEnabled ? 8 : 10)

        return self
            .scaleEffect(scaleValue, anchor: .trailing)
            .rotationEffect(rotationValue)
            .offset(x: minXValue)
            .offset(x: excessMinXValue)
    }

    // MARK: - Helper Functions
    private func progress(proxy: GeometryProxy, limit: CGFloat = 2) -> CGFloat {
        let maxX = proxy.frame(in: .scrollView(axis: .horizontal)).maxX
        let width = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
        let progress = (maxX / width) - 1.0
        return min(progress, limit)
    }

    private func scale(proxy: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
        let progress = progress(proxy: proxy)
        return 1 - (progress * scale)
    }

    private func rotation(proxy: GeometryProxy, rotation: CGFloat = 5) -> Angle {
        let progress = progress(proxy: proxy)
        return .degrees(progress * rotation)
    }

    private func minX(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        return minX < 0 ? 0 : -minX
    }

    private func excessMinX(proxy: GeometryProxy, offset: CGFloat = 10) -> CGFloat {
        let progress = progress(proxy: proxy)
        return progress * offset
    }
}
