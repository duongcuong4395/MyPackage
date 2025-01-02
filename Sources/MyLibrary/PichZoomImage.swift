//
//  PichZoomImage.swift
//  MyLibrary
//
//  Created by Macbook on 2/1/25.
//

import SwiftUI

@available(iOS 17.0, *)
extension View {
    func pinchZoom(_ dimsBackground: Bool = true) -> some View {
        PinchZoomHelper(dimsBackgound: dimsBackground) {
            self
        }
    }
}

@available(iOS 17.0, *)
struct ZoomContainer<Content: View>: View {
    var content: Content
    
    //@ViewBuilder var content: Content
    private var containerData = ZoomContainerData()
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    //@available(iOS 17.0, *)
    var body: some View {
        GeometryReader{ _ in
            content
                .environment(containerData)
            
            ZStack(alignment: .topLeading) {
                
                if let view = containerData.zoomingView {
                    Group {
                        if containerData.dimsBackgound {
                            Rectangle()
                                .fill(.black.opacity(0.25))
                                .opacity(containerData.zoom - 1)
                        }
                        
                        view
                            .scaleEffect(containerData.zoom, anchor: containerData.zoomAnchor)
                            .offset(containerData.dragOffset)
                            .offset(x: containerData.viewRect.minX, y: containerData.viewRect.minY)
                    }
                    
                }
            }
            .ignoresSafeArea()
        }
    }
}

@available(iOS 17.0, *)
@Observable
fileprivate class ZoomContainerData {
    var zoomingView: AnyView?
    var viewRect: CGRect = .zero
    
    var dimsBackgound: Bool = false
    var zoom: CGFloat = 1
    
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    
    var isReseting: Bool = false
}


@available(iOS 17.0, *)
fileprivate struct PinchZoomHelper<Content: View>: View {
    var dimsBackgound: Bool
    @ViewBuilder var content: Content
    @Environment(ZoomContainerData.self) private var containerData
    @State var config: Config = .init()
    var body: some View {
        content
            .opacity(config.hideSourceView ? 0 : 1)
            .overlay(GestureOverlay(config: $config))
            .overlay(content: {
                GeometryReader {
                    let rect = $0.frame(in: .global)
                    Color.clear
                        .onChange(of: config.isGestureActive) { oldValue, newValue in
                            if newValue {
                                guard !containerData.isReseting else { return }
                                containerData.viewRect = rect
                                containerData.zoomAnchor = config.zoomAnchor
                                containerData.dimsBackgound = dimsBackgound
                                containerData.zoomingView = .init(erasing: content  )
                                config.hideSourceView = true
                            } else {
                                containerData.isReseting = true
                                withAnimation(.snappy(duration: 0.3, extraBounce:0), completionCriteria: .logicallyComplete) {
                                    containerData.dragOffset = .zero
                                    containerData.zoom = 1
                                } completion: {
                                    config = .init()
                                    containerData.zoomingView = nil
                                    containerData.isReseting = false
                                }
                            }
                        }
                        .onChange(of: config) { oldValue, newValue in
                            if config.isGestureActive && !containerData.isReseting {
                                containerData.zoom = config.zoom
                                containerData.dragOffset = config.dragOffset
                            } else {
                                
                            }
                        }
                }
            })
            
    }
}

import UIKit
/// UIkit Gesture overlay
@available(iOS 13.0, *)
fileprivate struct GestureOverlay: UIViewRepresentable {
    @Binding var config: Config
    func makeCoordinator() -> Coordinator {
        Coordinator(config: $config)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "PinchPanGesture"
        panGesture.minimumNumberOfTouches = 2
        panGesture.addTarget(context.coordinator, action: #selector(Coordinator.panGesture(gesture: )))
        panGesture.delegate = context.coordinator
        
        view.addGestureRecognizer(panGesture)
        
        let pinGesture = UIPinchGestureRecognizer()
        pinGesture.name = "PinchZoomGesture"
        pinGesture.addTarget(context.coordinator, action: #selector(Coordinator.pinGesture(gesture: )))
        pinGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var config: Config
        
        init(config: Binding<Config>) {
            self._config = config
        }
        
        @objc
        func panGesture(gesture: UIPanGestureRecognizer) {
            if  gesture.state == .began || gesture.state == .changed {
                let transition = gesture.translation(in: gesture.view)
                config.dragOffset = .init(width: transition.x, height: transition.y)
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        @objc
        func pinGesture(gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                if let bounds = gesture.view?.bounds {
                    config.zoomAnchor = .init(x: location.x / bounds.width, y: location.y / bounds.height)
                }
            }
            if  gesture.state == .began || gesture.state == .changed {
                let scale = max(gesture.scale, 1)
                config.zoom = scale
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer.name == "PinchPanGesture" && otherGestureRecognizer.name == "PinchZoomGesture" {
                return true
            }
            
            return false
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct Config: Equatable {
    var isGestureActive: Bool = false
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var hideSourceView: Bool = false
}
