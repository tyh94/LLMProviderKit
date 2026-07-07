//
//  OpenAICompatibleSetupForm.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import SwiftUI

struct OpenAICompatibleSetupForm: View {
    let onAdd: (LLMClientConfiguration) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name    = ""
    @State private var baseURL = ""
    @State private var model   = ""
    @State private var apiKey  = ""
    @State private var error: String?
    @FocusState private var focused: Field?

    private enum Field { case name, url, model, apiKey }

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

            Section(String(localized: "llm.openai.presets.section", bundle: .module)) {
                presetRow(
                    String(localized: "llm.openai.preset.ollama", bundle: .module),
                    url: "http://localhost:11434",
                    model: "minimax-m3:cloud"
                )
                presetRow(
                    String(localized: "llm.openai.preset.llamacpp", bundle: .module),
                    url: "http://localhost:8080",
                    model: ""
                )
                presetRow(
                    String(localized: "llm.openai.preset.groq", bundle: .module),
                    url: "https://api.groq.com/openai",
                    model: "llama-3.1-8b-instant"
                )
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
                Button(String(localized: "llm.add.button", bundle: .module)) { save() }
                    .fontWeight(.semibold)
                    .disabled(baseURL.isEmpty || name.isEmpty)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "llm.done.button", bundle: .module)) { focused = nil }
            }
        }
    }

    private func presetRow(_ title: String, url: String, model: String) -> some View {
        Button {
            if name.isEmpty { self.name = title }
            self.baseURL = url
            self.model   = model
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func save() {
        let configuration = LLMClientConfiguration(
            name: name,
            systemImage: "server.rack",
            provider: .openAICompatible(
                displayName: name,
                baseURL: baseURL,
                model: model,
                apiKey: apiKey.isEmpty ? nil : apiKey
            )
        )

        onAdd(configuration)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        OpenAICompatibleSetupForm(onAdd: { _ in })
    }
}
