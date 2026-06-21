//
//  LLMProvider.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import Foundation

/// Провайдер LLM. Принимает системный промпт + пользовательский текст,
/// возвращает любой Decodable-тип (JSON парсится автоматически).
public protocol LLMProvider: Sendable {
    /// Отображаемое имя провайдера (для UI)
    var displayName: String { get }

    /// Отправить запрос и вернуть десериализованный объект типа T.
    /// Системный промпт должен инструктировать модель возвращать JSON.
    func complete<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type
    ) async throws -> T
}

// MARK: - LLMClient

/// Удобная обёртка: держит текущего провайдера, добавляет
/// стандартный JSON-суффикс к системному промпту.
public final class LLMClient: Sendable {
    public let provider: any LLMProvider

    public init(provider: any LLMProvider) {
        self.provider = provider
    }

    /// Отправить запрос. Провайдер сам обязан вернуть валидный JSON —
    /// `jsonSuffix` добавляется к `system` автоматически.
    public func complete<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type = T.self
    ) async throws -> T {
        let fullSystem = system + "\n\n" + jsonSuffix
        return try await provider.complete(system: fullSystem, user: user, as: type)
    }

    // MARK: - Private

    private let jsonSuffix = """
    IMPORTANT: Respond with ONLY a valid JSON object. \
    No markdown, no code fences, no explanation — raw JSON only.
    """
}

// MARK: - JSON extraction helper (shared across providers)

extension String {
    /// Вырезает первый JSON-объект или массив из строки.
    /// Убирает ```json … ``` если модель добавила их.
    func extractedJSON() -> String {
        var s = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // Убираем markdown fence
        if s.hasPrefix("```") {
            s = s.replacingOccurrences(
                of: #"```(?:json)?\n?"#,
                with: "",
                options: .regularExpression
            )
            s = s.replacingOccurrences(of: "```", with: "")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Берём от первого { или [ до парного закрывающего
        let openers: [Character] = ["{", "["]
        let closers: [Character: Character] = ["{": "}", "[": "]"]

        guard let firstChar = s.first(where: { openers.contains($0) }),
              let startIdx = s.firstIndex(of: firstChar),
              let closer = closers[firstChar],
              let endIdx = s.lastIndex(of: closer)
        else { return s }

        return String(s[startIdx...endIdx])
    }
}
