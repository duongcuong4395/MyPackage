//
//  TextToSpeech.swift
//  MyLibrary
//
//  Created by Macbook on 5/4/25.
//

import AVFoundation
import SwiftUI

public enum SpeechStyle: CaseIterable, Identifiable {
    case friendly
    case dramatic
    case funny
    case serious
    case robotic
    case sad
    case sarcastic
    case energetic
    case calm

    public var id: String { title }

    public var config: (rate: Float, pitch: Float, volume: Float) {
        switch self {
        case .friendly:   return (0.5, 1.3, 1.0)
        case .dramatic:   return (0.45, 1.0, 1.0)
        case .funny:      return (0.7, 1.6, 1.0)
        case .serious:    return (0.4, 0.9, 1.0)
        case .robotic:    return (0.55, 0.7, 0.9)
        case .sad:        return (0.4, 0.85, 0.7)
        case .sarcastic:  return (0.6, 1.1, 1.0)
        case .energetic:  return (0.75, 1.4, 1.0)
        case .calm:       return (0.45, 1.0, 0.8)
        }
    }

    public var title: String {
        switch self {
        case .friendly: return "Thân thiện"
        case .dramatic: return "Kịch tính"
        case .funny: return "Hài hước"
        case .serious: return "Nghiêm túc"
        case .robotic: return "Robot"
        case .sad: return "Buồn"
        case .sarcastic: return "Châm biếm"
        case .energetic: return "Nhiệt huyết"
        case .calm: return "Điềm tĩnh"
        }
    }

    public var icon: String {
        switch self {
        case .friendly: return "face.smiling"
        case .dramatic: return "theatermasks"
        case .funny: return "face.dashed"
        case .serious: return "face.smiling.inverse"
        case .robotic: return "cpu"
        case .sad: return "cloud.drizzle"
        case .sarcastic: return "eyebrow"
        case .energetic: return "bolt"
        case .calm: return "leaf"
        }
    }
}

@available(iOS 17.0, *)
// MARK: - TextToSpeechManager
@MainActor
public final class TextToSpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = TextToSpeechManager()

    private lazy var synthesizer: AVSpeechSynthesizer = {
        let syn = AVSpeechSynthesizer()
        syn.delegate = self
        return syn
    }()
    
    public var onHighlightRange: (@MainActor (NSRange) -> Void)?
    
    public func speak(
        text: String,
        language: String = "vi-VN",
        style: SpeechStyle = .friendly,
        voiceIdentifier: String? = nil
    ) {
        if synthesizer.isSpeaking {
            stopSpeaking()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        let config = style.config
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitch
        utterance.volume = config.volume

        utterance.voice = {
            if let id = voiceIdentifier {
                return AVSpeechSynthesisVoice(identifier: id)
            } else {
                return AVSpeechSynthesisVoice(language: language)
            }
        }()

        synthesizer.speak(utterance)
    }

    public func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onHighlightRange?(range)
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            onHighlightRange?(NSRange(location: 0, length: 0))
        }
    }
}





@available(iOS 17.0.0, *)
public struct TextToSpeechViewModifier: ViewModifier {
    
    private var text: String
    private var style: SpeechStyle
    
    public init(text: String, style: SpeechStyle) {
        self.text = text
        self.style = style
    }
    
    
    public func body(content: Content) -> some View {
        content
            .onTapGesture {
                TextToSpeechManager.shared.speak(
                    text: text,
                    style: style
                )
            }
    }
}

@available(iOS 17.0.0, *)
public extension View {
    func textToSpeech(text: String, style: SpeechStyle) -> some View {
        self.modifier(TextToSpeechViewModifier(text: text, style: style))
    }
}





import Foundation
import AVFoundation

@available(iOS 17.0, *)
// MARK: - TextToSpeechManager
@MainActor
public final class TextToSpeechManager2: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = TextToSpeechManager2()

    private let synthesizer = AVSpeechSynthesizer()
    private var fullText: NSString = ""
    
    public var onHighlightRange: ((NSRange) -> Void)?
    public var onFinish: (() -> Void)?
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(
        text: String,
        language: String = "vi-VN",
        style: SpeechStyle = .friendly,
        voiceIdentifier: String? = nil
    ) {
        if synthesizer.isSpeaking {
            stopSpeaking()
            return
        }

        fullText = NSString(string: text)
        let utterance = AVSpeechUtterance(string: text)
        let config = style.config

        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitch
        utterance.volume = config.volume
        utterance.voice = voiceIdentifier != nil
            ? AVSpeechSynthesisVoice(identifier: voiceIdentifier!)
            : AVSpeechSynthesisVoice(language: language)

        synthesizer.speak(utterance)
    }

    public func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            //onHighlightRange?(range)
            onHighlightRange?(characterRange)
        }
        
    }

    nonisolated public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            onHighlightRange?(NSRange(location: 0, length: 0)) // clear
            onFinish?()
        }
        
    }
}
