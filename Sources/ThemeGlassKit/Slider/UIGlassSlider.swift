//
//  UIGlassSlider.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//
import SwiftUI

@available(iOS 14.0, *)
public struct UIGlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    @State private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let hapticGenerator = UISelectionFeedbackGenerator()
    
    public init(value: Binding<Double>, in range: ClosedRange<Double>) {
        self._value = value
        self.range = range
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let knobPosition = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * trackWidth
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: knobPosition, height: 6)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 28 : 24, height: isDragging ? 28 : 24)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .position(x: knobPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    hapticGenerator.selectionChanged()
                                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.1)) {
                                        isDragging = true
                                    }
                                }
                                
                                let newValue = Double(gesture.location.x / trackWidth) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                            .onEnded { _ in
                                withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
                                    isDragging = false
                                }
                            }
                    )
            }
        }
        .frame(height: 44)
        .onAppear {
            hapticGenerator.prepare()
        }
        .accessibilityElement()
        .accessibilityLabel("Slider")
        .accessibilityValue("\(Int(value * 100))%")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 0.1, range.upperBound)
            case .decrement:
                value = max(value - 0.1, range.lowerBound)
            @unknown default:
                break
            }
        }
    }
}
