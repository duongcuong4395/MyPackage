//
//  OTPCode.swift
//  MyLibrary
//
//  Created by Macbook on 10/2/25.
//

import SwiftUI

@available(IOS 16.0, *)
// Properties
public enum CodeType: Int, CaseIterable {
    case four = 4
    case six = 6

    var stringValue: String {
        "\(rawValue) Digit"
    }
}

public enum TypingState {
    case typing
    case valid
    case invalid
}

public enum TextFieldStyle: String, CaseIterable {
    case roundedBorder = "Rounded Border"
    case underlined = "Underlined"
}

@available(IOS 16.0, *)
public struct VerificationField: View {
    var type: CodeType
    var style: TextFieldStyle = .roundedBorder
    @Binding var value: String
    var onchange: (String) async -> TypingState
    @State private var state: TypingState = .typing
    
    @FocusState private var isActive: Bool
    @State private var invalidTrigger: Bool = false
    
    init(type: CodeType, style: TextFieldStyle, value: String, onchange: @escaping (String) -> TypingState) {
        self.type = type
        self.style = style
        self.value = value
    }
    
    public var body: some View {
        HStack(spacing: style == .roundedBorder ? 6 : 10) {
            ForEach(0..<type.rawValue, id: \.self) { index in
                CharacterView(index)
            }
        }
        .animation(.easeOut(duration: 0.2), value: value)
        .animation(.easeOut(duration: 0.2), value: isActive)
        .compositingGroup()
        // invalid phase animation
        .phaseAnimator([0, 10, -10, 10, -5, 5, 0], trigger: invalidTrigger, content: { content, offset in
            content
                .offset(x: offset)
        }, animation: { _ in
                .linear(duration: 0.06)
        })
        
        .background{
            TextField("", text: $value)
                .focused($isActive)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .mask(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 1, height: 1)
                        .opacity(0.1)
                }
                .allowsHitTesting(false)
        }
        .contentShape(.rect)
        .onTapGesture {
            isActive = true
        }
        .onChange(of: value) { oldValue, newValue in
            value = String(newValue.prefix(type.rawValue))
            Task { @MainActor in
                state = await onchange(value)
                if state == .invalid {
                    invalidTrigger.toggle()
                }
            }
        }
        .toolbar{
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isActive = false
                }
                .tint(Color.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
            }
        }
        
    }
    
    @ViewBuilder
    func CharacterView(_ index: Int) -> some View {
        Group {
            if style == .roundedBorder {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor(index), lineWidth: 1.2)
            } else {
                Rectangle()
                    .fill(borderColor(index))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(width: style == .roundedBorder ? 50 : 40, height: 50)
        .overlay {
            let stringValue = string(index)
            if stringValue != "" {
                Text(stringValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .transition(.blurReplace)
            }
        }
    }

    func string(_ index: Int) -> String {
        if value.count > index {
            let startIndex = value.startIndex
            let stringIndex = value.index(startIndex, offsetBy: index)
            return String(value[stringIndex])
        }
        return ""
    }

    func borderColor(_ index: Int) -> Color {
        switch state {
            // highlight when typing
        case .typing: return value.count == index && isActive ? Color.primary : .gray
        case .valid: return .green
        case .invalid: return .red
        }
    }
}

@available(IOS 16.0, *)
public struct DemoOTPCodeView: View {
    @State private var code: String = ""
    var body: some View {
        VerificationField(type: .four, style: .underlined, value: $code) { result in
            if result.count < 4 {
                return .typing
            } else if result == "1234" {
                return.valid
            } else {
                return .invalid
            }
        }
    }
}
