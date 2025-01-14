//
//  StackedCards.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/25.
//

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
                                .modifier(CardEffectModifier(
                                    geometryProxy: proxy,
                                    isRotationEnabled: isRotationEnabled
                                ))
                                .zIndex(items.zIndex(item))
                        }
                    }
                    .padding(.vertical, 15)
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(showsIndicator ? .visible : .hidden)
            }
            
            /*
            // Optional UI Controls
            VStack(spacing: 10) {
                Toggle("Enable Rotation", isOn: $isRotationEnabled)
                Toggle("Show Scroll Indicator", isOn: $showsIndicator)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding()
            */
        }
    }
}

@available(iOS 17.0, *)
struct CardEffectModifier: ViewModifier {
    public let geometryProxy: GeometryProxy
    public let isRotationEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale(geometryProxy: geometryProxy), anchor: .trailing)
            .rotationEffect(rotation(geometryProxy: geometryProxy))
            .offset(x: minXOffset(geometryProxy: geometryProxy))
            .offset(x: additionalOffset(geometryProxy: geometryProxy))
    }
    
    // MARK: - Helper Functions
    private func progress(geometryProxy: GeometryProxy, limit: CGFloat = 2) -> CGFloat {
        let maxX = geometryProxy.frame(in: .scrollView(axis: .horizontal)).maxX
        let width = geometryProxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
        let progress = (maxX / width) - 1.0
        return min(progress, limit)
    }
    
    private func scale(geometryProxy: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
        let progress = progress(geometryProxy: geometryProxy)
        return 1 - (progress * scale)
    }
    
    private func rotation(geometryProxy: GeometryProxy, rotationAngle: CGFloat = 5) -> Angle {
        guard isRotationEnabled else { return .degrees(0) }
        let progress = progress(geometryProxy: geometryProxy)
        return .degrees(progress * rotationAngle)
    }
    
    private func minXOffset(geometryProxy: GeometryProxy) -> CGFloat {
        let minX = geometryProxy.frame(in: .scrollView(axis: .horizontal)).minX
        return minX < 0 ? 0 : -minX
    }
    
    private func additionalOffset(geometryProxy: GeometryProxy, offset: CGFloat = 8) -> CGFloat {
        let progress = progress(geometryProxy: geometryProxy)
        return progress * offset
    }
}
