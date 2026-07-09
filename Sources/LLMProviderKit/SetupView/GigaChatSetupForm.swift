//
//  GigaChatSetupForm.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import SwiftUI

struct GigaChatSetupForm: View {
    let onSave: (LLMClientConfiguration) -> Void
    private let editing: LLMClientConfiguration?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var authorizationKey: String
    @State private var model: GigaChatModel
    @State private var scope: GigaChatScope
    @FocusState private var focused: Field?

    private enum Field { case name, authKey }

    /// - Parameter editing: существующая конфигурация для редактирования; `nil` — создание новой.
    init(
        editing: LLMClientConfiguration? = nil,
        onSave: @escaping (LLMClientConfiguration) -> Void
    ) {
        self.editing = editing
        self.onSave = onSave
        var name = "GigaChat", authKey = "", model = GigaChatModel.lite, scope = GigaChatScope.personal
        if case let .gigaChat(displayName, authorizationKey, mdl, scp) = editing?.provider {
            name = displayName
            authKey = authorizationKey
            model = GigaChatModel(rawValue: mdl) ?? .lite
            scope = GigaChatScope(rawValue: scp) ?? .personal
        }
        _name = State(initialValue: name)
        _authorizationKey = State(initialValue: authKey)
        _model = State(initialValue: model)
        _scope = State(initialValue: scope)
    }

    /// Тип доступа GigaChat — определяет `scope` в запросе токена.
    private enum GigaChatScope: String, CaseIterable, Identifiable {
        case personal = "GIGACHAT_API_PERS"
        case business = "GIGACHAT_API_B2B"
        case corporate = "GIGACHAT_API_CORP"

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .personal: return "llm.gigachat.scope.personal"
            case .business: return "llm.gigachat.scope.business"
            case .corporate: return "llm.gigachat.scope.corporate"
            }
        }
    }

    /// Доступные модели GigaChat.
    private enum GigaChatModel: String, CaseIterable, Identifiable {
        case lite = "GigaChat"
        case pro = "GigaChat-Pro"
        case max = "GigaChat-Max"

        var id: String { rawValue }
    }

    var body: some View {
        List {
            Section {
                LabeledContent(String(localized: "llm.openai.name.label", bundle: .module)) {
                    TextField(String(localized: "llm.openai.name.placeholder", bundle: .module), text: $name)
                        .multilineTextAlignment(.trailing)
                        .focused($focused, equals: .name)
                }
            } header: {
                Text(String(localized: "llm.gigachat.credentials.header", bundle: .module))
            }

            Section {
                SecureField(
                    String(localized: "llm.gigachat.authkey.placeholder", bundle: .module),
                    text: $authorizationKey
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused, equals: .authKey)
            } header: {
                Text(String(localized: "llm.gigachat.authkey.label", bundle: .module))
            } footer: {
                Text(String(localized: "llm.gigachat.authkey.footer", bundle: .module))
                    .font(.caption)
            }

            Section {
                Picker(String(localized: "llm.gigachat.scope.label", bundle: .module), selection: $scope) {
                    ForEach(GigaChatScope.allCases) { scope in
                        Text(scope.title, bundle: .module).tag(scope)
                    }
                }
                Picker(String(localized: "llm.openai.model.label", bundle: .module), selection: $model) {
                    ForEach(GigaChatModel.allCases) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
            }

            Section {
                Text(String(localized: "llm.openai.preset.gigachat.instructions", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "llm.openai.instructions.header", bundle: .module))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "llm.gigachat.navigation.title", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saveButtonTitle) { save() }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || authorizationKey.isEmpty)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "llm.done.button", bundle: .module)) { focused = nil }
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
            systemImage: editing?.systemImage ?? "server.rack",
            provider: .gigaChat(
                displayName: name,
                authorizationKey: authorizationKey.trimmingCharacters(in: .whitespacesAndNewlines),
                model: model.rawValue,
                scope: scope.rawValue
            )
        )

        onSave(configuration)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GigaChatSetupForm(onSave: { _ in })
    }
}
