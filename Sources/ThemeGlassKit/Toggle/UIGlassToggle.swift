//
//  UIGlassToggle.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//
import SwiftUI

@available(iOS 14.0, *)
public struct UIGlassToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    public init(isOn: Binding<Bool>, label: String) {
        self._isOn = isOn
        self.label = label
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(isOn ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .offset(x: isOn ? 10 : -10)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .onTapGesture {
                hapticGenerator.impactOccurred()
                let animation: Animation? = reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)
                withAnimation(animation) {
                    isOn.toggle()
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            hapticGenerator.prepare()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}
