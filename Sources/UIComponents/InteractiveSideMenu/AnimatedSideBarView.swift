//
//  AnimatedSideBarView.swift
//  MyLibrary
//
//  Created by Macbook on 30/3/25.
//

// https://www.youtube.com/watch?v=GlTJ8LK9mq4&t=60s

import SwiftUI

@available(iOS 17.0, *)
public struct AnimatedSideBar<Content: View
                        , MenuView: View
                        , Background: View>: View {
    /// Customization Options

    var rotatesWhenExpands: Bool = true
    var disablesInteraction: Bool = true

    var sideMenuWidth: CGFloat = 200
    var cornerRadius: CGFloat = 25

    @Binding var showMenu: Bool
    @ViewBuilder var content: (UIEdgeInsets) -> Content

    @ViewBuilder var menuView: (UIEdgeInsets) -> MenuView
    @ViewBuilder var background: () -> Background

    /// View Properties
    @GestureState private var isDragging: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    /// Used to Dim Content View When Side Bar is Being Dragged
    @State private var progress: CGFloat = 0
    
    public init(
        rotatesWhenExpands: Bool,
        disablesInteraction: Bool,
        sideMenuWidth: CGFloat,
        cornerRadius: CGFloat,
        showMenu: Binding<Bool>,
        content: @escaping (UIEdgeInsets) -> Content,
        menuView: @escaping (UIEdgeInsets) -> MenuView,
        @ViewBuilder background: @escaping () -> Background
    ) {
        self.rotatesWhenExpands = rotatesWhenExpands
        self.disablesInteraction = disablesInteraction
        self.sideMenuWidth = sideMenuWidth
        self.cornerRadius = cornerRadius
        self._showMenu = showMenu
        self.content = content
        self.menuView = menuView
        self.background = background
        
    }
    
    public var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets ?? .zero

            HStack(spacing: 0) {
                GeometryReader { _ in
                    menuView(safeArea)
                }
                .frame(width: sideMenuWidth)
                /// Clipping Menu Interaction Beyond it's Width
                .contentShape(.rect)

                GeometryReader { _ in
                    content(safeArea)
                }
                .frame(width: size.width)
                .overlay {
                    if disablesInteraction && progress > 0 {
                        Rectangle()
                            .fill(.black.opacity(progress * 0.2))
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                    reset()
                                }
                            }
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: progress * cornerRadius)
                }
                .scaleEffect(rotatesWhenExpands ? 1 - (progress * 0.1) : 1, anchor: .trailing)
                .rotation3DEffect(
                    .init(degrees: rotatesWhenExpands ? (progress * -15) : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
            }
            .frame(width: size.width + sideMenuWidth, height: size.height)
            .offset(x: -sideMenuWidth)
            
            .offset(x: offsetX)
            .contentShape(.rect)
            //.gesture(dragGesture)
            .simultaneousGesture(dragGesture)
        }
        .background(background())
        .ignoresSafeArea()
        .onChange(of: showMenu, initial: true) { oldValue, newValue in
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                if newValue {
                    showSideBar()
                } else {
                    reset()
                }
            }
            
        }
    }
    
    /// Drag Gesture
    var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, out, _ in
                out = true
            }
            .onChanged { value in
                guard value.startLocation.x > 10 else { return }
                
                let translationX = isDragging ? max(min(value.translation.width + lastOffsetX, sideMenuWidth), 0) : 0
                offsetX = translationX
                calculateProgress()
            }
            .onEnded { value in
                guard value.startLocation.x > 10 else { return }
                
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    let velocityX = value.velocity.width / 8
                    let total = velocityX + offsetX
                    
                    if total > (sideMenuWidth * 0.5) {
                        showSideBar()
                    } else {
                        reset()
                    }
                }
            }
    }
    
    /// Show's Side Bar
    func showSideBar() {
        offsetX = sideMenuWidth
        lastOffsetX = offsetX
        showMenu = true
        calculateProgress()
    }

    /// Reset's to it's Initial State
    func reset() {
        offsetX = 0
        lastOffsetX = 0
        showMenu = false
        calculateProgress()
    }

    /// Convert's Offset into Series of progress ranging from 0 - 1
    func calculateProgress() {
        progress = max(min(offsetX / sideMenuWidth, 1), 0)
    }
}
