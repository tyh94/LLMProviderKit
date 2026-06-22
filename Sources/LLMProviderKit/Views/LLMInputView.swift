//
//  LLMInputView 2.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 17.06.2026.
//

import SwiftUI

/// Универсальный экран ввода текста с выбором провайдера и парсингом через LLM.
///
/// ```swift
/// LLMInputView(
///     clients: [
///         LLMClientOption(client: LLMClient(provider: gigaChat)),
///         LLMClientOption(client: LLMClient(provider: ollama), systemImage: "server.rack"),
///     ],
///     systemPrompt: "Parse this recipe and return JSON…",
///     placeholder: "Paste recipe text here…",
///     resultType: ParsedRecipeDTO.self,
///     usageLimit: LLMUsageLimit(used: 1, total: 3),
///     preview: { dto in RecipePreviewView(dto: dto) },
///     onConfirm: { dto in recipeStore.add(Recipe(from: dto)) }
/// )
/// ```
public struct LLMInputView<Result: Decodable & Sendable, Preview: View>: View {
    private let clients: [LLMClientOption]
    private let systemPrompt: String
    private let placeholder: String
    private let resultType: Result.Type
    private let usageLimit: LLMUsageLimit?
    private let onUpgradeTap: (() -> Void)?
    private let preview: (Result) -> Preview
    private let onConfirm: (Result) -> Void

    public init(
        clients: [LLMClientOption],
        systemPrompt: String,
        placeholder: String? = nil,
        resultType: Result.Type,
        usageLimit: LLMUsageLimit? = nil,
        onUpgradeTap: (() -> Void)? = nil,
        @ViewBuilder preview: @escaping (Result) -> Preview,
        onConfirm: @escaping (Result) -> Void
    ) {
        self.clients = clients
        self.systemPrompt = systemPrompt
        self.placeholder = placeholder ?? String(localized: "llm.input.placeholder", bundle: .module)
        self.resultType = resultType
        self.usageLimit = usageLimit
        self.onUpgradeTap = onUpgradeTap
        self.preview = preview
        self.onConfirm = onConfirm
    }

    /// Удобный init для одного клиента (пикер не показывается)
    public init(
        client: LLMClient,
        systemPrompt: String,
        placeholder: String? = nil,
        resultType: Result.Type,
        usageLimit: LLMUsageLimit? = nil,
        @ViewBuilder preview: @escaping (Result) -> Preview,
        onConfirm: @escaping (Result) -> Void
    ) {
        self.init(
            clients: [LLMClientOption(client: client)],
            systemPrompt: systemPrompt,
            placeholder: placeholder,
            resultType: resultType,
            usageLimit: usageLimit,
            preview: preview,
            onConfirm: onConfirm
        )
    }

    // MARK: - State

    @State private var selectedId: String = ""
    @State private var inputText: String = ""
    @State private var state: ViewState = .idle
    @FocusState private var isEditing: Bool

    private enum ViewState {
        case idle
        case loading
        case result(Result)
        case error(String)
    }

    private var selectedClient: LLMClientOption {
        clients.first { $0.id == selectedId } ?? clients[0]
    }

    // MARK: - Body

    public var body: some View {
        List {
            if clients.count > 1 {
                clientPickerSection
            }
            
            // Секция с лимитами
            if let limit = usageLimit {
                usageLimitSection(limit)
            }

            inputSection

            switch state {
            case .idle:
                EmptyView()
            case .loading:
                loadingSection
            case .result(let result):
                previewSection(result)
            case .error(let message):
                errorSection(message)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            if selectedId.isEmpty { selectedId = clients[0].id }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if case .result(let result) = state {
                    Button(String(localized: "llm.input.confirm.button", bundle: .module)) {
                        onConfirm(result)
                    }
                    .fontWeight(.semibold)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "llm.input.done.button", bundle: .module)) {
                    isEditing = false
                }
            }
        }
        .animation(.default, value: stateTag)
    }

    // MARK: - Usage limit section

    private func usageLimitSection(_ limit: LLMUsageLimit) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: limit.hasRemaining ? "gauge.medium" : "gauge.with.dots.needle.0percent")
                        .foregroundStyle(limit.hasRemaining ? .blue : .orange)
                    
                    Text(
                        limit.hasRemaining
                            ? String(
                                localized: "llm.usage.remaining",
                                bundle: .module
                              ).replacingOccurrences(of: "%d", with: String(limit.remaining))
                            : String(localized: "llm.usage.exhausted", bundle: .module)
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(limit.used)/\(limit.total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Прогресс-бар
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor(for: limit))
                            .frame(
                                width: max(0, min(geometry.size.width * limit.usagePercentage, geometry.size.width)),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                
                if let resetDate = limit.resetDate {
                    Text(
                        String(
                            localized: "llm.usage.reset",
                            bundle: .module
                        ).replacingOccurrences(
                            of: "%@",
                            with: resetDate.formatted(date: .abbreviated, time: .shortened)
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                
                if !limit.hasRemaining && limit.upgradeAvailable {
                    Button {
                        onUpgradeTap?()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("llm.more.usage", bundle: .module)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.yellow)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(String(localized: "llm.usage.section.title", bundle: .module))
        }
    }
    
    private func progressColor(for limit: LLMUsageLimit) -> Color {
        let percentage = limit.usagePercentage
        switch percentage {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .yellow
        case 0.8..<1.0:
            return .orange
        default:
            return .red
        }
    }

    // MARK: - Client picker section

    private var clientPickerSection: some View {
        Section {
            ForEach(clients) { option in
                Button {
                    guard option.id != selectedId else { return }
                    selectedId = option.id
                    if case .result = state { state = .idle }
                    if case .error  = state { state = .idle }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.systemImage)
                            .foregroundStyle(option.id == selectedId ? Color.accentColor : Color.secondary)
                            .frame(width: 24)

                        Text(option.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if option.id == selectedId {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Text(String(localized: "llm.provider.section.title", bundle: .module))
        }
    }

    // MARK: - Input section

    private var inputSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $inputText)
                    .focused($isEditing)
                    .frame(height: 300)
                    .onChange(of: inputText) { _, _ in resetResultIfNeeded() }
            }
            .frame(height: 300)

            Button(action: parse) {
                Label(
                    String(localized: "llm.input.parse.button", bundle: .module)
                        .replacingOccurrences(of: "%@", with: selectedClient.displayName),
                    systemImage: selectedClient.systemImage
                )
                .frame(maxWidth: .infinity)
            }
            .disabled(
                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                isLoading ||
                !(usageLimit?.hasRemaining ?? true) // Блокируем если лимит исчерпан
            )
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
        }
    }

    // MARK: - Loading section

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text(
                        String(localized: "llm.input.parsing", bundle: .module)
                            .replacingOccurrences(of: "%@", with: selectedClient.displayName)
                    )
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
                Spacer()
            }
            .padding(.vertical, 24)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Preview section

    private func previewSection(_ result: Result) -> some View {
        Section(String(localized: "llm.input.preview.section", bundle: .module)) {
            preview(result)
        }
    }

    // MARK: - Error section

    private func errorSection(_ message: String) -> some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "llm.error.title", bundle: .module))
                        .fontWeight(.medium)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if clients.count > 1, let next = nextClient {
                        Button(
                            String(localized: "llm.error.retry.with", bundle: .module)
                                .replacingOccurrences(of: "%@", with: next.displayName)
                        ) {
                            selectedId = next.id
                            parse()
                        }
                        .font(.caption)
                        .padding(.top, 2)
                    } else {
                        Button(String(localized: "llm.error.retry.button", bundle: .module)) {
                            parse()
                        }
                        .font(.caption)
                        .padding(.top, 2)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Action

    private func parse() {
        guard usageLimit?.hasRemaining ?? true else {
            state = .error(String(localized: "llm.usage.limit.exceeded", bundle: .module))
            return
        }
        
        isEditing = false
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        state = .loading
        let client = selectedClient.client

        Task {
            do {
                let result = try await client.complete(
                    system: systemPrompt,
                    user: text,
                    as: resultType
                )
                state = .result(result)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    private var stateTag: String {
        switch state {
        case .idle:    return "idle"
        case .loading: return "loading"
        case .result:  return "result"
        case .error:   return "error"
        }
    }

    private var nextClient: LLMClientOption? {
        guard let currentIndex = clients.firstIndex(where: { $0.id == selectedId }),
              clients.count > 1
        else { return nil }
        let nextIndex = (currentIndex + 1) % clients.count
        return clients[nextIndex]
    }

    private func resetResultIfNeeded() {
        if case .result = state { state = .idle }
        if case .error  = state { state = .idle }
    }
}

// MARK: - Preview

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

#Preview {
    NavigationStack {
        LLMInputView(
            clients: [
                LLMClientOption(client: LLMClient(provider: _MockProvider()), displayName: "GigaChat", systemImage: "sparkle"),
            ],
            systemPrompt: "Parse and return JSON",
            resultType: _PreviewResult.self,
            usageLimit: LLMUsageLimit(
                used: 10,
                total: 10,
                resetDate: Date().addingTimeInterval(86400),
                upgradeAvailable: true
            ),
            preview: { result in
                Text(result.title)
            },
            onConfirm: { _ in }
        )
        .navigationTitle("Import")
    }
}
