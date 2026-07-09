//
//  LLMInputViewManaged.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 17.06.2026.
//

import SwiftUI

/// LLMInputView с управлением провайдерами прямо внутри view.
public struct LLMInputViewManaged<Result: Decodable & Sendable, Preview: View>: View {
    @Environment(LLMClientService.self) private var llmService
    public let systemPrompt: String
    public let placeholder: String
    public let resultType: Result.Type
    public let usageLimit: LLMUsageLimit?
    public let onUpgradeTap: (() -> Void)?
    public let preview: (Result) -> Preview
    public let onGetResult: ((Result) -> Void)?
    public let onConfirm: (Result) -> Void

    @State private var showSetup = false

    public init(
        systemPrompt: String,
        placeholder: String? = nil,
        resultType: Result.Type,
        usageLimit: LLMUsageLimit? = nil,
        onUpgradeTap: (() -> Void)? = nil,
        @ViewBuilder preview: @escaping (Result) -> Preview,
        onGetResult: ((Result) -> Void)?,
        onConfirm: @escaping (Result) -> Void
    ) {
        self.systemPrompt = systemPrompt
        self.placeholder = placeholder ?? String(localized: "llm.input.placeholder", bundle: .module)
        self.resultType = resultType
        self.usageLimit = usageLimit
        self.onUpgradeTap = onUpgradeTap
        self.preview = preview
        self.onGetResult = onGetResult
        self.onConfirm = onConfirm
    }
    
    @ViewBuilder
    var content: some View {
        if llmService.clients.isEmpty {
            emptyState
        } else {
            LLMInputView(
                clients: llmService.clients,
                systemPrompt: systemPrompt,
                placeholder: placeholder,
                resultType: resultType,
                usageLimit: usageLimit,
                onUpgradeTap: onUpgradeTap,
                preview: preview,
                onGetResult: onGetResult,
                onConfirm: onConfirm
            )
        }
    }
    
    public var body: some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSetup = true
                    } label: {
                        Image(systemName: llmService.clients.isEmpty ? "plus.circle.fill" : "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showSetup) {
                NavigationStack {
                    providerManagementView
                }
            }
            .task {
                try? await llmService.load()
            }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "llm.providers.empty.title", bundle: .module),
                systemImage: "sparkles"
            )
        } description: {
            Text(String(localized: "llm.providers.empty.description", bundle: .module))
        } actions: {
            Button(String(localized: "llm.providers.add.button", bundle: .module)) {
                showSetup = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var providerManagementView: some View {
        List {
            if !llmService.clients.isEmpty {
                Section(String(localized: "llm.providers.active.section", bundle: .module)) {
                    ForEach(llmService.clients) { option in
                        providerRow(option)
                    }
                }
            }

            Section {
                NavigationLink {
                    LLMProviderSetupView { newOption in
                        Task {
                           try? await llmService.add(newOption)
                            showSetup = false
                        }
                    }
                } label: {
                    Text(String(localized: "llm.providers.add.button", bundle: .module))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "llm.providers.title", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "llm.cancel.button", bundle: .module)) {
                    showSetup = false
                }
            }
        }
    }

    /// Строка провайдера. Настраиваемые (со своим `configurationId`) открываются на редактирование
    /// и удаляются свайпом; встроенные (локальные) — только помечены замком.
    @ViewBuilder
    private func providerRow(_ option: LLMClientOption) -> some View {
        if let config = configuration(for: option) {
            NavigationLink {
                editForm(for: config)
            } label: {
                providerLabel(option, editable: true)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    Task { try? await llmService.remove(id: config.id) }
                } label: {
                    Label(String(localized: "llm.delete.button", bundle: .module), systemImage: "trash")
                }
            }
        } else {
            providerLabel(option, editable: false)
        }
    }

    private func providerLabel(_ option: LLMClientOption, editable: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: option.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(option.displayName)
            Spacer()
            if !editable {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func configuration(for option: LLMClientOption) -> LLMClientConfiguration? {
        guard let id = option.configurationId else { return nil }
        return llmService.configurations.first { $0.id == id }
    }

    /// Форма редактирования для конкретного провайдера, предзаполненная и сохраняющая через `update`.
    @ViewBuilder
    private func editForm(for config: LLMClientConfiguration) -> some View {
        let onSave: (LLMClientConfiguration) -> Void = { updated in
            Task {
                try? await llmService.update(updated)
                showSetup = false
            }
        }
        switch config.provider {
        case .openAICompatible:
            OpenAICompatibleSetupForm(editing: config, onSave: onSave)
        case .gigaChat:
            GigaChatSetupForm(editing: config, onSave: onSave)
        }
    }
}

private struct _PreviewResult: Decodable, Sendable {
    let title: String
    let summary: String
}

private struct _MockProvider: LLMProvider {
    let displayName = "Mock"
    func complete<T: Decodable & Sendable>(system: String, user: String, as type: T.Type) async throws -> T {
        try await Task.sleep(for: .seconds(1))
        let json = #"{"title": "Пшеничный хлеб", "summary": "Простой рецепт на закваске"}"#
        return try JSONDecoder().decode(type, from: json.data(using: .utf8)!)
    }
}

import MKVNetwork

#Preview {
    NavigationStack {
        LLMInputViewManaged(
            systemPrompt: "Parse and return JSON",
            resultType: _PreviewResult.self,
            usageLimit: LLMUsageLimit(used: 3, total: 3, resetDate: Date().addingTimeInterval(86400)),
            preview: { result in Text(result.title) },
            onGetResult: { _ in },
            onConfirm: { _ in }
        )
        .navigationTitle("Import")
        .environment(LLMClientService(
            localClients: [],
            store: LLMConfigurationStoreMock(configs: []),
            network: NetworkManagerMock(),
            tokenStorage: .init(constant: TokenStorageMock())
        ))
    }
}
