//
//  DeviceRotation.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//

import SwiftUI

@available(iOS 16.0, *)
public struct DetectOrientation: ViewModifier {
    @Binding public var orientation: UIDeviceOrientation
    
    public init(orientation: Binding<UIDeviceOrientation>) {
        self._orientation = orientation
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
            }
    }
}

@available(iOS 16.0, *)
public extension View {
    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        modifier(DetectOrientation(orientation: orientation))
    }
}

@available(iOS 16.0, *)
struct OrientationExample: View {
    
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        VStack {
            if orientation.isLandscape {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("DevTechie")
                    Image(systemName: "heart.fill")
                }
                .font(.largeTitle)
                .foregroundColor(.orange)
            } else {
                VStack {
                    Image(systemName: "heart.fill")
                    Text("DevTechie")
                    Image(systemName: "heart.fill")
                }
                .font(.largeTitle)
                .foregroundColor(.orange)
            }
        }.detectOrientation($orientation)
    }
}
