//
//  SwipePanGesture.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//

import SwiftUI

public struct PanGestureValue {
    public var translation: CGSize = .zero
    public var velocity: CGSize = .zero
    
    public init(translation: CGSize = .zero, velocity: CGSize = .zero) {
        self.translation = translation
        self.velocity = velocity
    }
}

public extension CGPoint {
    var toSize: CGSize {
        return CGSize(width: x, height: y)
    }
}

// MARK: - UIView PanGesture Wrapper (iOS 18+)
@available(iOS 18, *)
public struct PanGestureRecognizerView: UIViewRepresentable {
    public var onBegan: () -> ()
    public var onChange: (PanGestureValue) -> ()
    public var onEnded: (PanGestureValue) -> ()

    public func makeCoordinator() -> Coordinator {
        Coordinator(onBegan: onBegan, onChange: onChange, onEnded: onEnded)
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleGesture(_:)))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}

    public class Coordinator: NSObject {
        public var onBegan: () -> ()
        public var onChange: (PanGestureValue) -> ()
        public var onEnded: (PanGestureValue) -> ()

        public init(onBegan: @escaping () -> (), onChange: @escaping (PanGestureValue) -> (), onEnded: @escaping (PanGestureValue) -> ()) {
            self.onBegan = onBegan
            self.onChange = onChange
            self.onEnded = onEnded
        }

        @MainActor @objc
        public func handleGesture(_ recognizer: UIPanGestureRecognizer) {
            let state = recognizer.state
            let translation = recognizer.translation(in: recognizer.view)
            let velocity = recognizer.velocity(in: recognizer.view)

            let gestureValue = PanGestureValue(translation: translation.toSize, velocity: velocity.toSize)

            switch state {
            case .began:
                onBegan()
            case .changed:
                onChange(gestureValue)
            case .ended, .cancelled:
                onEnded(gestureValue)
            default:
                break
            }
        }
    }
}


// MARK: - PanGestureViewModifier (iOS 17+)
/*
struct PanGestureViewModifier: ViewModifier {
    var onBegan: () -> ()
    var onChange: (CGSize, CGSize) -> ()
    var onEnded: (CGSize, CGSize) -> ()

    @GestureState private var isActive = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation
                        let velocity = CGSize(width: value.velocity.width, height: value.velocity.height)
                        onChange(translation, velocity)
                    }
                    .onEnded { value in
                        let translation = value.translation
                        let velocity = CGSize(width: value.velocity.width, height: value.velocity.height)
                        onEnded(translation, velocity)
                    }
                    .updating($isActive) { _, state, _ in
                        if !state {
                            onBegan()
                        }
                        state = true
                    }
            )
    }
}
*/
@available(iOS 13.0, *)
public struct PanGestureViewModifier: ViewModifier {
    public var onBegan: () -> ()
    public var onChange: (CGSize, CGSize) -> ()
    public var onEnded: (CGSize, CGSize) -> ()

    @GestureState private var isActive = false

    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation
                        let velocity = value.velocity//.toSize
                        onChange(translation, velocity)
                    }
                    .onEnded { value in
                        let translation = value.translation
                        let velocity = value.velocity//.toSize
                        onEnded(translation, velocity)
                    }
                    .updating($isActive) { _, state, _ in
                        guard !state else { return }
                        onBegan()
                        state = true
                    }
            )
    }
}



// MARK: - View Extension
@available(iOS 13.0, *)
public extension View {
    func panGesture(
        onBegan: @escaping () -> (),
        onChange: @escaping (CGSize, CGSize) -> (),
        onEnded: @escaping (CGSize, CGSize) -> ()
    ) -> some View {
        if #available(iOS 18, *) {
            return AnyView(self.overlay(
                PanGestureRecognizerView(
                    onBegan: onBegan,
                    onChange: { value in onChange(value.translation, value.velocity) },
                    onEnded: { value in onEnded(value.translation, value.velocity) }
                )
            ))
        } else {
            return AnyView(self.modifier(
                PanGestureViewModifier(
                    onBegan: onBegan,
                    onChange: onChange,
                    onEnded: onEnded
                )
            ))
        }
    }
}

