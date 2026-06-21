//
//  LLMProviderSetupView.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

//
//  LLMProviderSetupView.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import SwiftUI

// MARK: - LLMProviderSetupView

/// Экран добавления/настройки провайдера.
/// Можно встроить в любое место приложения или открыть как sheet.
///
/// ```swift
/// LLMProviderSetupView { option in
///     clients.append(option)
/// }
/// ```
public struct LLMProviderSetupView: View {
    private let onAdd: (LLMClientConfiguration) -> Void

    public init(onAdd: @escaping (LLMClientConfiguration) -> Void) {
        self.onAdd = onAdd
    }

    enum ProviderType: String, CaseIterable, Identifiable {
        case openAICompatible = "OpenAI Compatible"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .openAICompatible: return "server.rack"
            }
        }

        var description: String {
            switch self {
            case .openAICompatible:
                return String(localized: "llm.provider.openai.description", bundle: .module)
            }
        }
    }

    public var body: some View {
        List {
            Section(String(localized: "llm.provider.section.title", bundle: .module)) {
                ForEach(ProviderType.allCases) { type in
                    NavigationLink(
                        destination: formView(for: type),
                        label:  {
                            HStack(spacing: 14) {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.tint)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.rawValue)
                                        .foregroundStyle(.primary)
                                        .fontWeight(.medium)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "llm.provider.navigation.title", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func formView(for type: ProviderType) -> some View {
        switch type {
        case .openAICompatible:
            OpenAICompatibleSetupForm(onAdd: onAdd)
        }
    }
}

#Preview {
    NavigationStack {
        LLMProviderSetupView { _ in }
    }
}
