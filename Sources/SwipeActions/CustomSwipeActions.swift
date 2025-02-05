//
//  CustomSwipeActions.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//

import SwiftUI
@available(iOS 16.0, *)
public struct Action: Identifiable {
    public var id = UUID().uuidString
    public var symbolImage: String
    public var tint: Color
    public var background: Color

    // Properties
    public var font: Font = .title3
    public var size: CGSize = .init(width: 45, height: 45)
    public var shape: some Shape = .circle
    public var action: (inout Bool) -> ()
}

// Swipe Action Builder
// Accepts a set of actions without any 'return' or 'commas' and returns it in an array format
@available(iOS 16.0, *)
@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components: Action...) -> [Action] {
        return components
    }
}

public struct ActionConfig {
    public var leadingPadding: CGFloat = 0
    public var trailingPadding: CGFloat = 10
    public var spacing: CGFloat = 10
    public var occupiesFullWidth: Bool = true
    
    public init() {}
}

@available(iOS 17.0, *)
public extension View {
    @ViewBuilder
    func swipeActions(config: ActionConfig = .init()
                      , @ActionBuilder actions: () -> [Action]) -> some View {
        self.modifier(CustomSwipeActionModifier(config: config, actions: actions()))
    }
}

@available(iOS 17.0, *)
@MainActor
@Observable
public class SwipeActionSharedData {
    static let shared = SwipeActionSharedData()
    var activeSwipeAction: String?
    
    public init() {}
}

@available(iOS 17.0, *)
fileprivate struct CustomSwipeActionModifier: ViewModifier {
    var config: ActionConfig
    var actions: [Action]
    @State private  var resetPositionTrigger: Bool = false
        
    @State private var offsetX: CGFloat = 0
    @State private var lastStoredOffsetX: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var progress: CGFloat = 0
    
    @State private var currentScrollOffset: CGFloat = 0
    @State private var storedScrollOffset: CGFloat?
    
    var shareData = SwipeActionSharedData.shared
    @State private var currentID: String = UUID().uuidString
    
    func body(content: Content) -> some View {
        content
            .overlay {
                Rectangle()
                    .foregroundStyle(.clear)
                    .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                    .overlay(alignment: .trailing) {
                        ActionsView()
                    }
            }
            .compositingGroup()
            .offset(x: offsetX)
            .offset(x: bounceOffset)
            .mask {
                Rectangle()
                    .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
            }
            .panGesture(onBegan: {
                gestureDidBegan()
            }, onChange: { translation, velocity in
                gestureDidChange(translation: translation)
            }, onEnded: { translation, velocity in
                gestureDidEnded(translation: translation, velocity: velocity)
            })
            .onChange(of: resetPositionTrigger) { oldValue, newValue in
                reset()
            }
            .onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .scrollView).minY
            } action: { newValue in
                if let storedScrollOffset, storedScrollOffset != newValue {
                    reset()
                }
            }
            .onChange(of: shareData.activeSwipeAction) { oldValue, newValue in
                if newValue != currentID && offsetX != 0 {
                    reset()
                }
            }
    }
    
    
    @ViewBuilder
    func ActionsView() -> some View {
        ZStack {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                
                
                GeometryReader { proxy in
                    let size = proxy.size // Lỗi tại đây: size chưa được khởi tạo
                    let spacing = config.spacing * CGFloat(index)
                    let offset = (CGFloat(index) * size.width) + spacing

                    Button(action: {
                        action.action(&resetPositionTrigger)
                    }) {
                        Image(systemName: action.symbolImage)
                            .font(action.font)
                            .foregroundStyle(action.tint)
                            .frame(width: size.width, height: size.height)
                            .background(action.background, in: action.shape)
                    }
                    .offset(x: offset * progress)
                }
                .frame(width: action.size.width, height: action.size.height)
            }
        }
        .visualEffect { content, proxy in
            content.offset(x: proxy.size.width)
        }
        .offset(x: config.leadingPadding)
    }
    
    /*
    @ViewBuilder
    func ActionsView() -> some View {
        ZStack {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                let size = action.size
                let spacing = config.spacing * CGFloat(index)
                let offset = (CGFloat(index) * size.width) + spacing

                Button(action: {
                    action.action(&resetPositionTrigger)
                }) {
                    Image(systemName: action.symbolImage)
                        .font(action.font)
                        .foregroundStyle(action.tint)
                        .frame(width: size.width, height: size.height)
                        .background(action.background, in: action.shape)
                }
                .offset(x: offset * progress)
            }
        }
        .offset(x: config.leadingPadding)
    }
    */

    
    private func gestureDidBegan() {
        DispatchQueue.main.async {
            storedScrollOffset = lastStoredOffsetX
            shareData.activeSwipeAction = currentID
        }
    }

    /*
    private func gestureDidChange(translation: CGSize) {
        offsetX = min(max(translation.width + lastStoredOffsetX, -maxOffsetWidth), 0)
        progress = -offsetX / maxOffsetWidth
        
        bounceOffset = min(translation.width - (offsetX - lastStoredOffsetX), 0) / 10
    }
    */
    
    private func gestureDidChange(translation: CGSize) {
        guard offsetX != min(max(translation.width + lastStoredOffsetX, -maxOffsetWidth), 0) else { return }
        
        offsetX = min(max(translation.width + lastStoredOffsetX, -maxOffsetWidth), 0)
        progress = -offsetX / maxOffsetWidth
        bounceOffset = min(translation.width - (offsetX - lastStoredOffsetX), 0) / 10
    }

    private func gestureDidEnded(translation: CGSize, velocity: CGSize) {
        let endTarget = velocity.width + offsetX // translation.width
        
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            if -endTarget > (maxOffsetWidth * 0.6) {
                offsetX = -maxOffsetWidth
                bounceOffset = 0
                progress = 1
            } else {
                // reset position
                reset()
            }
            
        }
        lastStoredOffsetX = offsetX
    }
    
    /*
    private func gestureDidEnded(translation: CGSize, velocity: CGSize) {
        let endTarget = offsetX + velocity.width
        let shouldOpen = -endTarget > (maxOffsetWidth * 0.6)
        
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            if shouldOpen {
                offsetX = -maxOffsetWidth
                progress = 1
            } else {
                reset()
            }
        }
        
        lastStoredOffsetX = offsetX
    }
    */

    
    func reset() {
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            offsetX = 0
            lastStoredOffsetX = 0
            bounceOffset = 0
            progress = 0
        }
        storedScrollOffset = nil
    }

    
    var maxOffsetWidth: CGFloat {
        let totalActionSize: CGFloat = actions.reduce(.zero) { partialResult, action in
            partialResult + action.size.width
        }
        let spacing = config.spacing * CGFloat(actions.count - 1)
        return totalActionSize + spacing + config.leadingPadding + config.trailingPadding
    }
    /*
    var maxOffsetWidth: CGFloat {
        if let cachedWidth = cachedMaxOffsetWidth {
            return cachedWidth
        }
        let totalActionSize = actions.reduce(CGFloat.zero) { $0 + $1.size.width }
        let spacing = config.spacing * CGFloat(actions.count - 1)
        let finalWidth = totalActionSize + spacing + config.leadingPadding + config.trailingPadding
        
        cachedMaxOffsetWidth = finalWidth
        return finalWidth
    }
    
    @State private var cachedMaxOffsetWidth: CGFloat?
    */
}
