//
//  ToastView.swift
//  MyLibrary
//
//  Created by Macbook on 28/2/25.
//

// https://www.youtube.com/watch?v=b6FVOXZT8So

import SwiftUI


/*
 struct ContentView: View {
     var body: some View {
         RootView {
             DemoToastView()
         }
         
     }
 }
 */

@available(iOS 17.0, *)
public struct DemoToastView: View {
    public init() { }
    
    public var body: some View {
        VStack {
            Button("Toats") {
                Toast.shared.present(title: "Hello word"
                                     , symbol: "globe"
                                     , isUserInteractionEnabled: false
                                     , timing: .long
                )
            }
        }
    }
}

@available(iOS 17.0, *)
public struct RootView<Content: View>: View {
    @ViewBuilder var content: Content

    @State private var overlayWindow: UIWindow?
    
    var alignment: VerticalAlignment // Thêm biến alignment

    public init(alignment: VerticalAlignment = .bottom, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.alignment = alignment
    }
    
    public var body: some View {
        content
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
                    let window = PassthroughWindow(windowScene: windowScene)
                    window.backgroundColor = .clear
                    
                    let rootController = UIHostingController(rootView: ToastGroup(alignment: alignment))
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    
                    window.rootViewController = rootController
                    
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    
                    overlayWindow = window
                }
            }
    }
}



fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard let view = super.hitTest(point, with: event) else { return nil }
        
        return rootViewController?.view == view ? nil : view
    }
}

@available(iOS 17.0, *)
@Observable
public class Toast {
    @MainActor public static let shared = Toast()
    fileprivate var toasts: [ToastItem] = []

    
    
    public func present(title: String, symbol: String?, tint: Color = .primary, isUserInteractionEnabled: Bool = false, timing: ToastTime = .medium) {
        
        withAnimation(.snappy) {
            toasts.append(.init(title: title, symbol: symbol, tint: tint, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing))
        }
        
    }
}

@available(iOS 17.0, *)
public struct ToastItem: Identifiable {
    public let id: UUID = .init()
    /// Custom Properties
    public var title: String
    public var symbol: String?
    public var tint: Color
    public var isUserInteractionEnabled: Bool
    /// Timing
    public var timing: ToastTime = .medium
}

@available(iOS 17.0, *)
public enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.5
}

@available(iOS 17.0, *)
fileprivate struct ToastGroup: View {
    var model = Toast.shared

    var alignment: VerticalAlignment // Thêm biến để điều chỉnh vị trí

    public init(alignment: VerticalAlignment = .bottom) {
        self.alignment = alignment
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let safeArea = geometry.safeAreaInsets

            ZStack {
                
                ForEach (model.toasts) { toast in
                    ToastView(size: size, item: toast, alignment: alignment)
                        .scaleEffect(scale(toast))
                        .offset(y: offsetY(toast))
                        .zIndex(Double(model.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
                }
                
            }
            //.padding(.bottom, safeArea.top == .zero ? 15 : 10)
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            .padding(.bottom, alignment == .bottom ? (safeArea.bottom == 0 ? 15 : 10) : 0)
            .padding(.top, alignment == .top ? (safeArea.top == 0 ? 15 : 10) : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment == .top ? .top : .bottom)
        }
    }
    
    func offsetY(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
    }
    
    func scale(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return 1 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
    }
}

@available(iOS 17.0, *)
fileprivate struct ToastView: View {
    var size: CGSize
    var item: ToastItem
    var alignment: VerticalAlignment // Nhận alignment để điều chỉnh animation

    @State private var delayTask: DispatchWorkItem?
    
    public init(size: CGSize, item: ToastItem, alignment: VerticalAlignment) {
        self.size = size
        self.item = item
        self.alignment = alignment
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .padding(.trailing, 10)
            }
            
            Text(item.title)
                //.lineLimit(1    )
        }
        .foregroundStyle(item.tint)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            .background
                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
            in: .capsule
        )
        .contentShape(.capsule)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    guard item.isUserInteractionEnabled else { return }
                    let endY = value.translation.height
                    let velocityY = value.velocity.height
                    
                    if (endY + velocityY) > 100 {
                        removeToast()
                    }
                }
        )
        
        .onAppear{
            guard delayTask == nil else { return }
            
            delayTask = .init(block: {
                removeToast()
            })
            
            if let delayTask {
                DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
            }
        }
        
        .frame(maxWidth: size.width * 0.7)
        //.transition(.offset(y: 150))
        .transition(alignment == .top ? .move(edge: .top) : .move(edge: .bottom))
    }
    
    func removeToast() {
        if let delayTask {
            delayTask.cancel()
        }
        
        withAnimation(.snappy) {
            Toast.shared.toasts.removeAll(where: { $0.id == item.id })
        }
    }
}
