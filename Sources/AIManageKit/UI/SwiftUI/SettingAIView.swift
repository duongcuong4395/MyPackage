//
//  SettingAIView.swift
//  SinTraffic
//
//  Created by Macbook on 9/3/26.
//
import Foundation
import SwiftUI

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Root View
// ═════════════════════════════════════════════════════════════════════════════

public enum AISettingMenu: String, CaseIterable, Hashable {
    case Key = "API Key"
    case Model = "Model"
}

@available(iOS 17.0, *)
public struct SettingAIView: View {

    @Environment(AIManager.self) private var aiManager
    //@EnvironmentObject var appVM: AppViewModel

    @State var menu: AISettingMenu = .Key
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Onboarding banner khi chưa có key ─────────────────
                if aiManager.keyStatus != .valid {
                    //AIOnboardingBannerView()
                }

                // ── Status (luôn hiển thị) ─────────────────────────────
                AIStatusSectionView()

                HStack(spacing: 15) {
                    Text(AISettingMenu.Key.rawValue)
                        .font(menu == .Key ? .caption.bold() : .caption)
                        .padding(5)
                        .background(.ultraThinMaterial.opacity(menu == .Key ? 1 : 0), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .onTapGesture {
                            withAnimation {
                                menu = .Key
                            }
                        }
                    Text(AISettingMenu.Model.rawValue)
                        .font(menu == .Model ? .caption.bold() : .caption)
                        .padding(5)
                        .background(.ultraThinMaterial.opacity(menu == .Model ? 1 : 0), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .onTapGesture {
                            withAnimation {
                                menu = .Model
                            }
                        }
                }
                
                ZStack {
                    if menu == .Key {
                        // ── Key management ─────────────────────────────────────
                        AIKeySectionView()
                            .opacity(menu == .Key ? 1 : 0)
                            .scaleEffect(menu == .Key ? 1 : 0)
                    } else {
                        // ── Model picker (chỉ có ý nghĩa khi key hợp lệ) ──────
                        AIModelSectionView()
                            .opacity(aiManager.keyStatus == .valid ? 1 : 0.45)
                            .disabled(aiManager.keyStatus != .valid)
                            .overlay(alignment: .topTrailing) {
                                if aiManager.keyStatus != .valid {
                                    Text("Requires valid key")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .padding(10)
                                }
                            }
                            .opacity(menu == .Model ? 1 : 0)
                            .scaleEffect(menu == .Model ? 1 : 0)
                    }
                }
            }
            //.padding(.horizontal, 16)
            //.padding(.vertical, 12)
        }
        .animation(.spring(duration: 0.35), value: aiManager.keyStatus)
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Onboarding Banner  (chỉ hiện khi chưa có key / key invalid)
// ═════════════════════════════════════════════════════════════════════════════

@available(iOS 17.0, *)
public struct AIOnboardingBannerView: View {

    @Environment(AIManager.self) private var aiManager

    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            // Icon + title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(aiManager.keyStatus == .invalid
                         ? "API Key Invalid"
                         : "Set Up AI Features")
                        .font(.headline)
                    Text(aiManager.keyStatus == .invalid
                         ? "Enter a valid Gemini API key to continue."
                         : "Add your Gemini API key to unlock AI-powered analysis.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            // Capability chips
            if aiManager.keyStatus == .notConfigured {
                HStack(spacing: 8) {
                    ForEach(["Traffic Analysis", "Station Info", "AI Insights"], id: \.self) { label in
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(label)
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                    }
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.07), .purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.25), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Section 1: Status
// ═════════════════════════════════════════════════════════════════════════════
@available(iOS 17.0, *)
public struct AIStatusSectionView: View {

    @Environment(AIManager.self) private var aiManager

    public init() {}
    
    public var body: some View {
        AISectionCard(title: "Status", systemImage: "antenna.radiowaves.left.and.right") {
            VStack(spacing: 10) {

                // Key status
                statusRow(
                    label: "API Key",
                    icon: "key.fill",
                    value: aiManager.keyStatus.label,
                    valueColor: aiManager.keyStatus.color,
                    dot: true
                )

                Divider()

                // Active model
                statusRow(
                    label: "Model",
                    icon: "cpu",
                    value: aiManager.configuration.model.displayName,
                    valueColor: .secondary,
                    dot: false
                )

                // Loading
                if aiManager.isLoading {
                    Divider()
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.75)
                        Text("Processing request…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                // Error
                if let error = aiManager.lastError {
                    Divider()
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(error.localizedDescription ?? "Unknown error")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(8)
                    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(
        label: String,
        icon: String,
        value: String,
        valueColor: Color,
        dot: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.subheadline)

            Spacer()

            /*
            if dot {
                Circle()
                    .fill(valueColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: valueColor.opacity(0.5), radius: 3)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true),
                               value: aiManager.isLoading)
            }
            */

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(valueColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(valueColor.opacity(0.1), in: Capsule())
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Section 2: API Key Management
// ═════════════════════════════════════════════════════════════════════════════

@available(iOS 17.0, *)
public struct AIKeySectionView: View {

    @Environment(AIManager.self) private var aiManager
    //@EnvironmentObject var appVM: AppViewModel

    @State private var keyInput: String = ""
    @State private var isEditing: Bool = false
    @State private var isValidating: Bool = false
    @State private var feedback: KeyFeedback? = nil
    @State private var showDeleteConfirm: Bool = false

    private enum KeyFeedback: Equatable {
        case success(String), error(String)
        var message: String {
            switch self { case .success(let m), .error(let m): return m }
        }
        var isError: Bool {
            if case .error = self { return true }; return false
        }
    }

    // Auto-open form nếu key chưa được cấu hình
    private var showForm: Bool {
        aiManager.keyStatus == .notConfigured
        || aiManager.keyStatus == .invalid
        || isEditing
    }
    
    public init() {}

    public var body: some View {
        AISectionCard(title: "API Key", systemImage: "key.fill") {
            VStack(spacing: 12) {

                // ── Khi đã có key và không editing ───────────────────
                if aiManager.keyStatus == .valid && !isEditing {
                    savedKeyRow
                } else {
                    // ── Form nhập key ──────────────────────────────────
                    keyInputField

                    // Feedback
                    if let fb = feedback {
                        feedbackRow(fb)
                    }

                    // Link + cancel
                    HStack {
                        getKeyLink
                        Spacer()
                        if isEditing {
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    isEditing = false
                                    keyInput = ""
                                    feedback = nil
                                }
                            } label: {
                                Text("Cancel")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    noteSection
                }
            }
        }
    }

    // MARK: Saved key state
    private var savedKeyRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Text("Key saved in Keychain")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.3)) { isEditing = true }
                } label: {
                    Label("Update", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }

            //getKeyLink
                //.frame(maxWidth: .infinity, alignment: .leading)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Remove saved key")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .confirmationDialog(
                "Remove API Key?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) { Task { await deleteKey() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The key will be permanently removed from Keychain.")
            }
        }
    }

    // MARK: Input field
    private var keyInputField: some View {
        // Binding that enforces a max length of 100 characters
        let limitedKeyBinding = Binding<String>(
            get: { keyInput },
            set: { newValue in
                if newValue.count > 100 {
                    keyInput = String(newValue.prefix(100))
                } else {
                    keyInput = newValue
                }
            }
        )

        return HStack(spacing: 8) {
            Image(systemName: "lock")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Divider().frame(height: 18)

            SecureField(
                NSLocalizedString("Title_Enter_Key", comment: "Enter API Key"),
                text: limitedKeyBinding
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .font(.subheadline)

            Divider().frame(height: 18)

            if isValidating {
                ProgressView().scaleEffect(0.75).frame(width: 44)
            } else {
                Button {
                    guard !keyInput.isEmpty else { return }
                    Task { await validateAndSave() }
                } label: {
                    Text(aiManager.keyStatus == .valid ? "Update" : "Save")
                        .font(.caption.weight(.bold))
                }
                .disabled(keyInput.isEmpty)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    @ViewBuilder
    private func feedbackRow(_ fb: KeyFeedback) -> some View {
        HStack(spacing: 6) {
            Image(systemName: fb.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .font(.caption)
            Text(fb.message).font(.caption)
        }
        .foregroundStyle(fb.isError ? .red : .green)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var getKeyLink: some View {
        Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right.circle").font(.caption2)
                Text(NSLocalizedString("getKeyByLink", comment: "Get key from Google AI Studio"))
                    .font(.caption)
            }
            .foregroundStyle(.blue)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach([
                NSLocalizedString("keyOnlyOnceInApp", comment: ""),
                NSLocalizedString("keyNotShare", comment: ""),
                NSLocalizedString("stableNetworkRequires", comment: "")
            ], id: \.self) { note in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("•").font(.caption2).foregroundStyle(.secondary)
                    Text(note + ".").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions
    private func validateAndSave() async {
        isValidating = true
        feedback = nil
        do {
            try await aiManager.setAPIKey(keyInput)
            withAnimation(.spring(duration: 0.35)) {
                feedback = .success("Key saved successfully.")
                isValidating = false
                isEditing = false
                keyInput = ""
            }
            // Đóng dialog nếu đây là lần đầu setup
            if aiManager.keyStatus == .valid {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // Không tự đóng — user vẫn có thể config model
                }
            }
        } catch let error as AIError {
            withAnimation {
                feedback = .error(error.localizedDescription ?? "Validation failed.")
                isValidating = false
                keyInput = ""
            }
        } catch {
            withAnimation {
                feedback = .error(error.localizedDescription)
                isValidating = false
                keyInput = ""
            }
        }
    }

    private func deleteKey() async {
        do {
            try await aiManager.deleteAPIKey()
            withAnimation { isEditing = false; keyInput = ""; feedback = nil }
        } catch {
            withAnimation { feedback = .error(error.localizedDescription) }
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Section 3: Model Management
// ═════════════════════════════════════════════════════════════════════════════

@available(iOS 17.0, *)
public struct AIModelSectionView: View {

    @Environment(AIManager.self) private var aiManager

    @State private var customModels: [AIModelType] = AIModelType.loadCustom()
    @State private var showAddSheet: Bool = false

    private var selectedIdentifier: String { aiManager.configuration.model.identifier }

    public init() {}
    
    public var body: some View {
        AISectionCard(title: "AI Model", systemImage: "cpu.fill") {
            VStack(spacing: 0) {

                modelGroupHeader("Predefined")
                ForEach(AIModelType.allPredefined, id: \.identifier) { model in
                    modelRow(model, isDeletable: false)
                    if model.identifier != lastOf(AIModelType.allPredefined) || !customModels.isEmpty {
                        Divider().padding(.leading, 36)
                    }
                }

                if !customModels.isEmpty {
                    modelGroupHeader("Custom")
                    ForEach(customModels, id: \.identifier) { model in
                        modelRow(model, isDeletable: true)
                        if model.identifier != lastOf(customModels) {
                            Divider().padding(.leading, 36)
                        }
                    }
                }

                Divider().padding(.top, 4)

                Button { showAddSheet = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.body)
                        Text("Add Custom Model")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCustomModelSheet { newModel in
                guard !customModels.contains(where: { $0.identifier == newModel.identifier }) else { return }
                customModels.append(newModel)
                AIModelType.saveCustom(customModels)
                selectModel(newModel)
            }
        }
    }

    // MARK: Row
    @ViewBuilder
    private func modelRow(_ model: AIModelType, isDeletable: Bool) -> some View {
        HStack(spacing: 12) {
            // Radio
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                if model.identifier == selectedIdentifier {
                    Circle().fill(.blue).frame(width: 12, height: 12)
                }
            }
            .animation(.spring(duration: 0.25), value: selectedIdentifier)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(.subheadline.weight(
                        model.identifier == selectedIdentifier ? .semibold : .regular
                    ))
                if let desc = model.description {
                    Text(desc).font(.caption).foregroundStyle(.secondary)
                }
                Text(model.identifier)
                    .font(.caption2).foregroundStyle(.tertiary).monospaced()
            }

            Spacer()

            if model.identifier == selectedIdentifier {
                Text("In use")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: Capsule())
            }

            if isDeletable {
                Button(role: .destructive) { deleteCustomModel(model) } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red.opacity(0.8))
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { selectModel(model) }
    }

    @ViewBuilder
    private func modelGroupHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .tracking(1)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    // MARK: Helpers
    private func lastOf(_ list: [AIModelType]) -> String { list.last?.identifier ?? "" }

    private func selectModel(_ model: AIModelType) {
        withAnimation(.spring(duration: 0.25)) { aiManager.switchModel(model) }
    }

    private func deleteCustomModel(_ model: AIModelType) {
        withAnimation {
            customModels.removeAll { $0.identifier == model.identifier }
            AIModelType.saveCustom(customModels)
            if selectedIdentifier == model.identifier {
                aiManager.switchModel(.gemini25FlashLite)
            }
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Add Custom Model Sheet
// ═════════════════════════════════════════════════════════════════════════════

@available(iOS 17.0, *)
public struct AddCustomModelSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var identifier: String = ""
    @State private var displayName: String = ""
    @State private var description: String = ""

    let onAdd: (AIModelType) -> Void

    private var canAdd: Bool { !identifier.trimmingCharacters(in: .whitespaces).isEmpty }

    private let examples: [(id: String, hint: String)] = [
        ("gemini-2.5-pro",        "Latest pro model"),
        ("gemini-2.0-flash-exp",  "Flash experimental"),
        ("gemini-1.5-flash-8b",   "Lightweight flash"),
        ("gemini-pro-vision",     "Vision capable"),
    ]

    public init(onAdd: @escaping (AIModelType) -> Void) {
        self.onAdd = onAdd
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Model identifier (required)", text: $identifier)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .monospaced()
                    TextField("Display name (optional)", text: $displayName)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Model Info")
                } footer: {
                    Text("Use the exact identifier from Google AI documentation.")
                }

                Section("Quick Fill") {
                    ForEach(examples, id: \.id) { ex in
                        Button {
                            identifier = ex.id
                            if displayName.isEmpty { displayName = ex.hint }
                        } label: {
                            HStack {
                                Text(ex.id).font(.caption.monospaced()).foregroundStyle(.primary)
                                Spacer()
                                Text(ex.hint).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Custom Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(AIModelType(
                            identifier: identifier.trimmingCharacters(in: .whitespaces),
                            displayName: displayName.isEmpty ? nil : displayName,
                            description: description.isEmpty ? nil : description
                        ))
                        dismiss()
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Reusable Card
// ═════════════════════════════════════════════════════════════════════════════
@available(iOS 17.0, *)
public struct AISectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    public init(title: String, systemImage: String, content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            .padding(.bottom, 10)

            content()
        }
        .padding(14)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - AIKeyStatus helpers
// ═════════════════════════════════════════════════════════════════════════════
@available(iOS 13.0, *)
public extension AIKeyStatus {
    
    var color: Color {
        switch self {
        case .valid:         return .green
        case .invalid:       return .red
        case .validating:    return .orange
        case .notConfigured: return .gray
        }
    }
    var label: String {
        switch self {
        case .valid:         return "Valid"
        case .invalid:       return "Invalid"
        case .validating:    return "Validating…"
        case .notConfigured: return "Not configured"
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - Custom Model Persistence
// ═════════════════════════════════════════════════════════════════════════════

private extension AIModelType {
    static let customModelsKey = "ai_custom_models_v1"

    static func loadCustom() -> [AIModelType] {
        guard let data = UserDefaults.standard.data(forKey: customModelsKey),
              let models = try? JSONDecoder().decode([AIModelType].self, from: data)
        else { return [] }
        return models
    }

    static func saveCustom(_ models: [AIModelType]) {
        guard let data = try? JSONEncoder().encode(models) else { return }
        UserDefaults.standard.set(data, forKey: customModelsKey)
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MARK: - AISettingsButton  (Toolbar shortcut)
// ═════════════════════════════════════════════════════════════════════════════

/// Place in the main view toolbar.
/// Badge color reflects keyStatus real-time; tap → open SettingsAIView.

@available(iOS 17.0, *)
public struct AISettingsButton: View {

    @Environment(AIManager.self) private var aiManager
    var action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "brain.head.profile")
                    .font(.body)

                // Status badge
                Circle()
                    .fill(aiManager.keyStatus.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: aiManager.keyStatus.color.opacity(0.6), radius: 3)
                    .offset(x: 5, y: -4)
            }
        }
        .accessibilityLabel("AI Settings — \(aiManager.keyStatus.label)")
        .animation(.spring(duration: 0.3), value: aiManager.keyStatus)
    }
}

