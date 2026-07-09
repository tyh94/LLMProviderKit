//
//  OpenAICompatibleSetupForm.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import SwiftUI

struct OpenAICompatibleSetupForm: View {
    let onSave: (LLMClientConfiguration) -> Void
    private let editing: LLMClientConfiguration?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var baseURL: String
    @State private var model: String
    @State private var apiKey: String
    @State private var error: String?
    @State private var selectedPreset: LLMPreset?
    @State private var showInstructions = false
    @FocusState private var focused: Field?

    private enum Field { case name, url, model, apiKey }

    /// - Parameter editing: существующая конфигурация для редактирования; `nil` — создание новой.
    init(
        editing: LLMClientConfiguration? = nil,
        onSave: @escaping (LLMClientConfiguration) -> Void
    ) {
        self.editing = editing
        self.onSave = onSave
        var name = "", baseURL = "", model = "", apiKey = ""
        if case let .openAICompatible(displayName, url, mdl, key, _, _) = editing?.provider {
            name = displayName; baseURL = url; model = mdl; apiKey = key ?? ""
        }
        _name = State(initialValue: name)
        _baseURL = State(initialValue: baseURL)
        _model = State(initialValue: model)
        _apiKey = State(initialValue: apiKey)
    }

    private var presets: [LLMPreset] {
        LLMPreset.all
    }
    
    private var selectedPresetInstructions: String? {
        selectedPreset?.instructions
    }
    
    private var selectedPresetWebsite: URL? {
        selectedPreset?.websiteURL
    }

    var body: some View {
        List {
            Section {
                LabeledContent(String(localized: "llm.openai.name.label", bundle: .module)) {
                    TextField(String(localized: "llm.openai.name.placeholder", bundle: .module), text: $name)
                        .multilineTextAlignment(.trailing)
                        .focused($focused, equals: .name)
                }
                LabeledContent(String(localized: "llm.openai.url.label", bundle: .module)) {
                    TextField(String(localized: "llm.openai.url.placeholder", bundle: .module), text: $baseURL)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .focused($focused, equals: .url)
                }
                LabeledContent(String(localized: "llm.openai.model.label", bundle: .module)) {
                    TextField(String(localized: "llm.openai.model.placeholder", bundle: .module), text: $model)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focused, equals: .model)
                }
                LabeledContent(String(localized: "llm.openai.apikey.label", bundle: .module)) {
                    SecureField(String(localized: "llm.openai.apikey.placeholder", bundle: .module), text: $apiKey)
                        .multilineTextAlignment(.trailing)
                        .focused($focused, equals: .apiKey)
                }
            } header: {
                Text(String(localized: "llm.openai.server.header", bundle: .module))
            } footer: {
                Text(String(localized: "llm.openai.server.footer", bundle: .module))
                    .font(.caption)
            }

            if let preset = selectedPreset {
                Section {
                    LLMProviderHelpView(preset: preset)
                    .padding(.vertical, 4)
                } header: {
                    Text(String(localized: "llm.openai.instructions.header", bundle: .module))
                }
            }

            Section(String(localized: "llm.openai.presets.section", bundle: .module)) {
                ForEach(presets) { preset in
                    presetRow(preset)
                }
            }

            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "llm.openai.navigation.title", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saveButtonTitle) { save() }
                    .fontWeight(.semibold)
                    .disabled(baseURL.isEmpty || name.isEmpty)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "llm.done.button", bundle: .module)) { focused = nil }
            }
        }
        .onChange(of: selectedPreset) { oldValue, newValue in
            if let preset = newValue {
                if name.isEmpty || name == oldValue?.displayName {
                    name = preset.displayName
                }
                baseURL = preset.baseURL
                model = preset.model
                if !preset.requiresApiKey {
                    apiKey = ""
                }
            }
        }
    }

    private func presetRow(_ preset: LLMPreset) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedPreset = preset
            }
        } label: {
            HStack {
                Image(systemName: preset.icon)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                
                Text(preset.displayName)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedPreset?.id == preset.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "arrow.up.left")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var saveButtonTitle: String {
        editing == nil
            ? String(localized: "llm.add.button", bundle: .module)
            : String(localized: "llm.save.button", bundle: .module)
    }

    private func save() {
        let configuration = LLMClientConfiguration(
            id: editing?.id ?? UUID(),
            name: name,
            systemImage: selectedPreset?.icon ?? editing?.systemImage ?? "server.rack",
            provider: .openAICompatible(
                displayName: name,
                baseURL: baseURL,
                model: model,
                apiKey: apiKey.isEmpty ? nil : apiKey
            )
        )

        onSave(configuration)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        OpenAICompatibleSetupForm(onSave: { _ in })
    }
}
