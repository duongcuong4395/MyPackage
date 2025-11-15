//
//  AIModelPickerView.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//


import SwiftUI

@available(iOS 17.0, *)
// MARK: - Model Picker View
public struct AIModelPickerView: View {
    @State private var aiManager: AIManager
    @State private var selectedModel: AIModelType
    @State private var customModels: [AIModelType] = []
    @State private var showAddCustomModel = false
    
    public init(aiManager: AIManager) {
        self.aiManager = aiManager
        self.selectedModel = aiManager.configuration.model
    }
    
    public var body: some View {
        List {
            Section {
                ForEach(AIModelType.allPredefined, id: \.identifier) { model in
                    modelRow(for: model)
                }
            } header: {
                Text("Predefined Models")
            }
            
            if !customModels.isEmpty {
                Section {
                    ForEach(customModels, id: \.identifier) { model in
                        modelRow(for: model)
                    }
                    .onDelete(perform: deleteCustomModels)
                } header: {
                    Text("Custom Models")
                }
            }
            
            Section {
                Button(action: { showAddCustomModel = true }) {
                    Label("Add Custom Model", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Select Model")
        .sheet(isPresented: $showAddCustomModel) {
            AddCustomModelView { newModel in
                customModels.append(newModel)
                selectModel(newModel)
            }
        }
    }
    
    private func modelRow(for model: AIModelType) -> some View {
        Button(action: { selectModel(model) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                    
                    if let description = model.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(model.identifier)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospaced()
                }
                
                Spacer()
                
                if model.identifier == selectedModel.identifier {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func selectModel(_ model: AIModelType) {
        selectedModel = model
        aiManager.switchModel(model)
    }
    
    private func deleteCustomModels(at offsets: IndexSet) {
        customModels.remove(atOffsets: offsets)
    }
}

@available(iOS 17.0, *)
// MARK: - Add Custom Model View
struct AddCustomModelView: View {
    @Environment(\.dismiss) var dismiss
    @State private var identifier = ""
    @State private var displayName = ""
    @State private var description = ""
    
    let onAdd: (AIModelType) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Model Identifier", text: $identifier)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .monospaced()
                    
                    TextField("Display Name (Optional)", text: $displayName)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Model Information")
                } footer: {
                    Text("Enter the exact model identifier from Google AI documentation (e.g., gemini-pro-vision)")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Model Identifiers:")
                            .font(.caption.bold())
                        
                        Group {
                            Text("• gemini-2.0-flash-exp")
                            Text("• gemini-1.5-pro-latest")
                            Text("• gemini-1.5-flash-8b")
                            Text("• gemini-pro-vision")
                        }
                        .font(.caption2)
                        .monospaced()
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Examples")
                }
            }
            .navigationTitle("Add Custom Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let model = AIModelType(
                            identifier: identifier,
                            displayName: displayName.isEmpty ? nil : displayName,
                            description: description.isEmpty ? nil : description
                        )
                        onAdd(model)
                        dismiss()
                    }
                    .disabled(identifier.isEmpty)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
// MARK: - Inline Model Picker (Compact)
public struct AIModelPickerCompact: View {
    @State private var aiManager: AIManager
    @State private var selectedModel: AIModelType
    
    public init(aiManager: AIManager) {
        self.aiManager = aiManager
        self.selectedModel = aiManager.configuration.model
    }
    
    public var body: some View {
        Menu {
            ForEach(AIModelType.allPredefined, id: \.identifier) { model in
                Button(action: { selectModel(model) }) {
                    HStack {
                        Text(model.displayName)
                        if model.identifier == selectedModel.identifier {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                Text(selectedModel.displayName)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    private func selectModel(_ model: AIModelType) {
        selectedModel = model
        aiManager.switchModel(model)
    }
}

/*
// MARK: - Preview
#Preview("Full Picker") {
    NavigationStack {
        AIModelPickerView(
            aiManager: AIManager(
                storage: MockAIStorage(initialKey: "test"),
                service: GeminiAIService()
            )
        )
    }
}
*/

/*
#Preview("Compact Picker") {
    AIModelPickerCompact(
        aiManager: AIManager(
            storage: MockAIStorage(initialKey: "test"),
            service: GeminiAIService()
        )
    )
}
*/
