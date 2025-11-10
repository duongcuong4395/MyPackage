//
//  UIGlassTabBar.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Optimized Tab Bar (Uncommented & Fixed)
@available(iOS 17.0, *)
public struct UIGlassTabBar: View {
    public var intensity: Double = 1.0
    @Binding var selection: Int
    let items: [TabItem2]
    
    @State private var activeIndicatorOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(intensity: Double = 1.0, selection: Binding<Int>, items: [TabItem2]) {
        self.intensity = intensity
        self._selection = selection
        self.items = items
    }
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    TabBarButton(
                        item: items[index],
                        isSelected: selection == index,
                        action: {
                            let animation: Animation? = reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7)
                            withAnimation(animation) {
                                selection = index
                                updateIndicatorPosition(for: index, width: geometry.size.width)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .modifier(
                UIGlassMaterial(
                    intensity: intensity,
                    tintColor: .white,
                    isInteractive: false
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 4)
                    .offset(x: activeIndicatorOffset)
                    .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7), value: activeIndicatorOffset),
                alignment: .bottom
            )
            .onAppear {
                updateIndicatorPosition(for: selection, width: geometry.size.width)
            }
        }
        .frame(height: 70)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab Bar")
    }
    
    private func updateIndicatorPosition(for index: Int, width: CGFloat) {
        let screenWidth = width - 20
        let buttonWidth = screenWidth / CGFloat(items.count)
        let offset = (buttonWidth * CGFloat(index)) + (buttonWidth / 2) - (screenWidth / 2)
        activeIndicatorOffset = offset
    }
}

public struct TabItem2 {
    public let title: String
    public let icon: String
    
    public init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
}

@available(iOS 17.0, *)
public struct TabBarButton: View {
    let item: TabItem2
    let isSelected: Bool
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    public var body: some View {
        Button(action: {
            hapticGenerator.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .scaleEffect(scale)
                
                Text(item.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .blue : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            hapticGenerator.prepare()
            scale = isSelected ? 1.1 : 1.0
        }
        .onChange(of: isSelected) { _, selected in
            let animation: Animation? = reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6)
            withAnimation(animation) {
                scale = selected ? 1.1 : 1.0
            }
        }
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
