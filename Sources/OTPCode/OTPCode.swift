//
//  OTPCode.swift
//  MyLibrary
//
//  Created by Macbook on 10/2/25.
//

import SwiftUI

@available(iOS 16.0, *)
// Properties
public enum CodeType: Int, CaseIterable {
    case four = 4
    case six = 6

    var stringValue: String {
        "\(rawValue) Digit"
    }
    
}

public enum TypingState: Sendable {
    case typing
    case valid
    case invalid
}

public enum TextFieldType: String, CaseIterable {
    case roundedBorder = "Rounded Border"
    case underlined = "Underlined"
}

@available(iOS 17.0, *)
public struct VerificationField: View {
    var type: CodeType
    var style: TextFieldType = .roundedBorder
    @Binding var useKeyboard: Bool
    @Binding var value: String
    var onchange: (String) async -> TypingState
    @State private var state: TypingState = .typing
    
    @FocusState private var isActive: Bool
    @State private var invalidTrigger: Bool = false
    
    
    
    public init(type: CodeType, style: TextFieldType
                , useKeyboard: Binding<Bool>
                , value: Binding<String>, onchange: @escaping (String) -> TypingState) {
        
        self.type = type
        self.style = style
        self._value = value
        self._useKeyboard = useKeyboard
        
        self.onchange = onchange
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
            if useKeyboard {
                isActive = true
            }
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
                //RoundedRectangle(cornerRadius: 10)
                    //.stroke(borderColor(index), lineWidth: 1.2)
                Circle()
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

public enum OTPState: String {
    case Typing
    case Valid
    case InValid
}


@available(iOS 17.0, *)
public struct OTPView: View {
    @Binding var code: String
    @Binding var useKeyboard: Bool
    var opt: (result: String, codeType: CodeType, textFieldType: TextFieldType)
    var onState: (OTPState) -> Void
    
    public init(code: Binding<String>, useKeyboard: Binding<Bool>, opt: (result: String, codeType: CodeType, textFieldType: TextFieldType), onState: @escaping (OTPState) -> Void) {
        self._code = code
        self._useKeyboard = useKeyboard
        self.opt = opt
        self.onState = onState
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            VerificationField(type: opt.codeType
                              , style: opt.textFieldType
                              , useKeyboard: $useKeyboard, value: $code) { result in
                if result.count < opt.codeType.rawValue {
                    onState(.Typing)
                    return .typing
                } else if result == opt.result {
                    onState(.Valid)
                    return .valid
                } else {
                    onState(.InValid)
                    return .invalid
                }
            }
            if !useKeyboard {
                HStack {
                    Spacer()
                    numbView(1)
                    Spacer()
                    numbView(2)
                    Spacer()
                    numbView(3)
                    Spacer()
                }
                HStack {
                    Spacer()
                    numbView(4)
                    Spacer()
                    numbView(5)
                    Spacer()
                    numbView(6)
                    Spacer()
                }
                HStack {
                    Spacer()
                    numbView(7)
                    Spacer()
                    numbView(8)
                    Spacer()
                    numbView(9)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Circle()
                    .stroke(.gray, lineWidth: 1.2)
                    .frame(width: UIScreen.main.bounds.width / 5)
                    .overlay {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .transition(.blurReplace)
                    }
                    .onTapGesture {
                        code = ""
                    }
                    Spacer()
                    numbView(0)
                    Spacer()
                    
                    
                    Circle()
                    .stroke(.gray, lineWidth: 1.2)
                    .frame(width: UIScreen.main.bounds.width / 5)
                    .overlay {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .transition(.blurReplace)
                    }
                    .onTapGesture {
                        self.code = String(code.dropLast())
                    }
                    Spacer()
                }
            }
            
        }
    }
    
    @ViewBuilder
    func numbView(_ numb: Int) -> some View {
        Circle()
        .stroke(.gray, lineWidth: 1.2)
        .frame(width: UIScreen.main.bounds.width / 5)
        .overlay {
            Text("\(numb)")
                .font(.title2)
                .fontWeight(.semibold)
                .transition(.blurReplace)
        }
        .onTapGesture {
            guard code.count < opt.result.count else { return }
            code += "\(numb)"
        }
    }
}

@available(iOS 17.0, *)
public struct OTPViewMod: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    var opt: (result: String, codeType: CodeType, textFieldType: TextFieldType) // (result: "1234", codeType: CodeType.four, textFieldType: TextFieldType.roundedBorder)
    
    @Binding var showOptView: Bool// = true
    @Binding var val: String// = ""
    @Binding var useKeyboard: Bool// = false
    
    public init(opt: (result: String, codeType: CodeType, textFieldType: TextFieldType)
         , showOptView: Binding<Bool>
         , val: Binding<String>
         , useKeyboard: Binding<Bool>) {
        
        self.opt = opt
        self._showOptView = showOptView
        self._val = val
        self._useKeyboard = useKeyboard
    }
    
    
    public func body(content: Content) -> some View {
        content
            .blur(radius: showOptView ? 50 : 0)
            .overlay {
                if showOptView {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.white.opacity(0.0001))
                            .frame(width: .infinity, height: .infinity)
                            .ignoresSafeArea(.all)
                        
                        OTPView(code: $val, useKeyboard: $useKeyboard, opt: opt) { state in
                            switch state {
                            case .Typing:
                                showOptView = true
                            case .Valid:
                                withAnimation(.spring()) {
                                    showOptView = false
                                }
                            case .InValid:
                                showOptView = true
                            }
                        }
                    }
                }
            }
        .onChange(of: scenePhase) { oldValue, newValue in
            withAnimation(.spring()) {
                val = ""
                showOptView = true
            }
            
        }
    }
}

@available(iOS 17.0, *)
public extension View {
    func OTPViewModifier(opt: (result: String, codeType: CodeType, textFieldType: TextFieldType)
        , showOptView: Binding<Bool>, val: Binding<String>, useKeyboard: Binding<Bool>) -> some View {
        modifier(OTPViewMod(opt: opt, showOptView: showOptView, val: val, useKeyboard: useKeyboard) )
    }
}
