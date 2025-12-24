//
//  GlassPlaygroundView.swift
//  MyLibrary
//
//  Created by Macbook on 13/11/25.
//

import SwiftUI





@available(iOS 15.0, *)
// MARK: - Interactive Playground View
public struct GlassPlaygroundView: View {
    @State private var backgroundImageURL: String = "https://fastly.picsum.photos/id/834/400/800.jpg?hmac=Wiroj1t99ncs3WtTOGuVrGzSpx13CZ0F319w-TMKvug"
    @State private var useGradientBackground = false
    
    // Glass parameters
    @State private var cornerRadius: Double = 16
    @State private var intensity: Double = 2.3
    @State private var tintColor: Color = .blue
    @State private var isInteractive: Bool = true
    @State private var hasShimmer: Bool = true
    @State private var hasGlow: Bool = true
    
    // Gradient settings
    @State private var gradientType: GradientType = .linear
    @State private var gradientStartX: Double = 0.0
    @State private var gradientStartY: Double = 0.0
    @State private var gradientEndX: Double = 1.0
    @State private var gradientEndY: Double = 1.0
    @State private var gradientCenterX: Double = 0.5
    @State private var gradientCenterY: Double = 0.5
    @State private var gradientStartRadius: Double = 10
    @State private var gradientEndRadius: Double = 150
    @State private var gradientStartAngle: Double = 0
    @State private var gradientEndAngle: Double = 360
    
    // Border settings
    @State private var borderType: BorderType = .gradient
    @State private var borderColor: Color = .white
    @State private var borderOpacity: Double = 0.5
    @State private var borderWidth: Double = 1.0
    
    @State private var blurRadius: Double = 0
    
    // Animation
    @State private var enableAnimations: Bool = true
    @State private var shimmerSpeed: Double = 2.0
    @State private var shimmerDelay: Double = 0.0
    @State private var glowSpeed: Double = 1.5
    @State private var glowDelay: Double = 0.0
    @State private var hoverSpeed: Double = 0.2
    
    public init() { }
    
    public var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 0) {
                Spacer()
                Button(action: {}) {
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 40))
                        Text("Glass Button")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 30)
                }
                .modifier(currentGlassMaterial)
                
                Spacer()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        basicParameters
                        Divider()
                        gradientSettings
                        Divider()
                        borderSettings
                        Divider()
                        effectsSettings
                        Divider()
                        codeExport
                    }
                    .padding()
                }
                .frame(maxHeight: 500)
                .background(Color(UIColor.systemBackground).opacity(0.93))
                .cornerRadius(25)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var currentGlassMaterial: GlassEffect {
        GlassEffect(
            cornerRadius: cornerRadius,
            intensity: intensity,
            tintColor: tintColor,
            isInteractive: isInteractive,
            hasShimmer: hasShimmer,
            hasGlow: hasGlow,
            gradientType: gradientType,
            gradientStart: UnitPoint(x: gradientStartX, y: gradientStartY),
            gradientEnd: UnitPoint(x: gradientEndX, y: gradientEndY),
            gradientCenterX: gradientCenterX,
            gradientCenterY: gradientCenterY,
            gradientStartRadius: CGFloat(gradientStartRadius),
            gradientEndRadius: CGFloat(gradientEndRadius),
            gradientStartAngle: gradientStartAngle,
            gradientEndAngle: gradientEndAngle,
            borderType: borderType,
            borderColor: borderColor,
            borderOpacity: borderOpacity,
            borderWidth: borderWidth,
            blurRadius: CGFloat(blurRadius),
            enableAnimations: enableAnimations,
            shimmerSpeed: shimmerSpeed,
            shimmerDelay: shimmerDelay,
            glowSpeed: glowSpeed,
            glowDelay: glowDelay,
            hoverAnimationSpeed: hoverSpeed
        )
    }
    
    private var backgroundView: some View {
        Group {
            if useGradientBackground {
                LinearGradient(
                    colors: [.blue, .purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                AsyncImage(url: URL(string: backgroundImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var basicParameters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Parameters")
                .font(.headline)
            
            HStack {
                Text("Corner Radius:")
                Spacer()
                Text("\(Int(cornerRadius))")
                    .foregroundColor(.secondary)
            }
            Slider(value: $cornerRadius, in: 0...50)
            
            HStack {
                Text("Intensity:")
                Spacer()
                Text(String(format: "%.2f", intensity))
                    .foregroundColor(.secondary)
            }
            Slider(value: $intensity, in: 0...10)
            
            ColorPicker("Tint Color", selection: $tintColor)
            Toggle("Interactive", isOn: $isInteractive)
        }
    }
    
    private var gradientSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gradient Settings")
                .font(.headline)
            
            Picker("Type", selection: $gradientType) {
                ForEach(GradientType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            switch gradientType {
            case .linear: linearGradientControls
            case .radial: radialGradientControls
            case .angular: angularGradientControls
            case .solid:
                Text("No gradient parameters")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private var linearGradientControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Point").font(.caption).foregroundColor(.secondary)
            HStack {
                Text("X:")
                Slider(value: $gradientStartX, in: 0...1)
                Text(String(format: "%.2f", gradientStartX)).frame(width: 40)
            }
            HStack {
                Text("Y:")
                Slider(value: $gradientStartY, in: 0...1)
                Text(String(format: "%.2f", gradientStartY)).frame(width: 40)
            }
            
            Text("End Point").font(.caption).foregroundColor(.secondary)
            HStack {
                Text("X:")
                Slider(value: $gradientEndX, in: 0...1)
                Text(String(format: "%.2f", gradientEndX)).frame(width: 40)
            }
            HStack {
                Text("Y:")
                Slider(value: $gradientEndY, in: 0...1)
                Text(String(format: "%.2f", gradientEndY)).frame(width: 40)
            }
        }
    }
    
    private var radialGradientControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Center").font(.caption).foregroundColor(.secondary)
            HStack {
                Text("X:")
                Slider(value: $gradientCenterX, in: 0...1)
                Text(String(format: "%.2f", gradientCenterX)).frame(width: 40)
            }
            HStack {
                Text("Y:")
                Slider(value: $gradientCenterY, in: 0...1)
                Text(String(format: "%.2f", gradientCenterY)).frame(width: 40)
            }
            HStack {
                Text("Start Radius:")
                Slider(value: $gradientStartRadius, in: 0...100)
                Text("\(Int(gradientStartRadius))").frame(width: 40)
            }
            HStack {
                Text("End Radius:")
                Slider(value: $gradientEndRadius, in: 0...300)
                Text("\(Int(gradientEndRadius))").frame(width: 40)
            }
        }
    }
    
    private var angularGradientControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Center").font(.caption).foregroundColor(.secondary)
            HStack {
                Text("X:")
                Slider(value: $gradientCenterX, in: 0...1)
                Text(String(format: "%.2f", gradientCenterX)).frame(width: 40)
            }
            HStack {
                Text("Y:")
                Slider(value: $gradientCenterY, in: 0...1)
                Text(String(format: "%.2f", gradientCenterY)).frame(width: 40)
            }
            HStack {
                Text("Start Angle:")
                Slider(value: $gradientStartAngle, in: 0...360)
                Text("\(Int(gradientStartAngle))°").frame(width: 50)
            }
            HStack {
                Text("End Angle:")
                Slider(value: $gradientEndAngle, in: 0...360)
                Text("\(Int(gradientEndAngle))°").frame(width: 50)
            }
        }
    }
    
    private var borderSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Border Settings")
                .font(.headline)
            
            Picker("Type", selection: $borderType) {
                ForEach(BorderType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if borderType != .none {
                ColorPicker("Border Color", selection: $borderColor)
                HStack {
                    Text("Opacity:")
                    Spacer()
                    Text(String(format: "%.2f", borderOpacity))
                        .foregroundColor(.secondary)
                }
                Slider(value: $borderOpacity, in: 0...1)
                
                HStack {
                    Text("Width:")
                    Spacer()
                    Text(String(format: "%.1f", borderWidth))
                        .foregroundColor(.secondary)
                }
                Slider(value: $borderWidth, in: 0.5...5)
            }
        }
    }
    
    private var effectsSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Effects")
                .font(.headline)
            /*
            Toggle("Enable Animations", isOn: $enableAnimations)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            */
            
            Divider()
            
            Toggle("Shimmer Effect", isOn: $hasShimmer)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
            
            /*
            if hasShimmer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text(String(format: "%.1fs", shimmerSpeed))
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $shimmerSpeed, in: 0.5...5)
                    
                    HStack {
                        Text("Delay:")
                        Spacer()
                        Text(String(format: "%.1fs", shimmerDelay))
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $shimmerDelay, in: 0...2)
                }
                .padding(.leading, 16)
            }
            */
            
            Divider()
            
            Toggle("Glow Effect", isOn: $hasGlow)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
            
            /*
            if hasGlow {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text(String(format: "%.1fs", glowSpeed))
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $glowSpeed, in: 0.5...5)
                    
                    HStack {
                        Text("Delay:")
                        Spacer()
                        Text(String(format: "%.1fs", glowDelay))
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    Slider(value: $glowDelay, in: 0...2)
                }
                .padding(.leading, 16)
            }
            */
            
            /*
            if isInteractive {
                Divider()
                HStack {
                    Text("Hover Speed:")
                    Spacer()
                    Text(String(format: "%.1fs", hoverSpeed))
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
                Slider(value: $hoverSpeed, in: 0.1...1)
            }
            */
            
            Divider()
            
            HStack {
                Text("Blur Radius:")
                Spacer()
                Text("\(Int(blurRadius))")
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
            Slider(value: $blurRadius, in: 0...20)
        }
    }
    
    private var codeExport: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Code")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(generateCode())
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            Button("Copy Code") {
                UIPasteboard.general.string = generateCode()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func generateCode() -> String {
        var code = ".modifier(GlassEffect(\n"
        code += "    cornerRadius: \(Int(cornerRadius)),\n"
        code += "    intensity: \(String(format: "%.2f", intensity)),\n"
        code += "    tintColor: \(colorCode(tintColor)),\n"
        //code += "    tintColor: .\(tintColor),\n"
        code += "    isInteractive: \(isInteractive),\n"
        code += "    hasShimmer: \(hasShimmer),\n"
        code += "    hasGlow: \(hasGlow),\n"
        code += "    gradientType: .\(gradientType.rawValue.lowercased()),\n"
        
        if gradientType == .linear {
            code += "    gradientStart: UnitPoint(x: \(String(format: "%.2f", gradientStartX)), y: \(String(format: "%.2f", gradientStartY))),\n"
            code += "    gradientEnd: UnitPoint(x: \(String(format: "%.2f", gradientEndX)), y: \(String(format: "%.2f", gradientEndY))),\n"
        } else if gradientType == .radial || gradientType == .angular {
            code += "    gradientCenterX: \(String(format: "%.2f", gradientCenterX)),\n"
            code += "    gradientCenterY: \(String(format: "%.2f", gradientCenterY)),\n"
        }
        
        if gradientType == .radial {
            code += "    gradientStartRadius: \(Int(gradientStartRadius)),\n"
            code += "    gradientEndRadius: \(Int(gradientEndRadius)),\n"
        }
        
        if gradientType == .angular {
            code += "    gradientStartAngle: \(Int(gradientStartAngle)),\n"
            code += "    gradientEndAngle: \(Int(gradientEndAngle)),\n"
        }
        
        code += "    borderType: .\(borderType.rawValue.lowercased()),\n"
        code += "    borderColor: \(colorCode(borderColor)),\n"
        code += "    borderOpacity: \(String(format: "%.2f", borderOpacity)),\n"
        code += "    borderWidth: \(String(format: "%.1f", borderWidth)),\n"
        code += "    blurRadius: \(Int(blurRadius)),\n"
        code += "    enableAnimations: \(enableAnimations),\n"
        code += "    shimmerSpeed: \(String(format: "%.1f", shimmerSpeed)),\n"
        code += "    shimmerDelay: \(String(format: "%.1f", shimmerDelay)),\n"
        code += "    glowSpeed: \(String(format: "%.1f", glowSpeed)),\n"
        code += "    glowDelay: \(String(format: "%.1f", glowDelay)),\n"
        code += "    hoverAnimationSpeed: \(String(format: "%.1f", hoverSpeed))\n"
        code += "))"
        
        return code
    }

    private func colorCode(_ color: Color) -> String {
        let known: [(Color, String)] = [
            (.blue, ".blue"),
            (.red, ".red"),
            (.green, ".green"),
            (.white, ".white"),
            (.black, ".black"),
            (.purple, ".purple"),
            (.orange, ".orange"),
            (.pink, ".pink"),
            (.yellow, ".yellow")
        ]

        for (c, name) in known where color == c {
            return name
        }

        guard let rgba = color.rgbaComponents() else {
            return ".clear"
        }

        return String(
            format: "Color(red: %.6f, green: %.6f, blue: %.6f, opacity: %.6f)",
            rgba.r, rgba.g, rgba.b, rgba.a
        )
    }

}




import SwiftUI
import UIKit


@available(iOS 14.0, *)
extension Color {
    func rgbaComponents() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        return (r, g, b, a)
    }
}

