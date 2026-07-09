//
//  GigaChatProvider.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import Foundation
import MKVNetwork

/// Специальный провайдер для GigaChat (Сбер)
/// Отличается от OpenAI-compatible тем, что требует двухэтапную авторизацию:
/// 1. Получение Access Token по Authorization Key
/// 2. Использование Access Token для запросов к API
final actor GigaChatProvider: LLMProvider {
    let displayName: String
    private let baseURL: String
    private let model: String
    private let authorizationKey: String
    private let scope: String
    private let network: NetworkManaging
    private let tokenStorage: TokenStorage?
    private let logger: LLMLogger?

    private var accessToken: String?
    private var tokenExpirationDate: Date?

    init(
        displayName: String = "GigaChat",
        baseURL: String = "https://gigachat.devices.sberbank.ru",
        model: String = "GigaChat",
        authorizationKey: String,
        scope: String = "GIGACHAT_API_PERS",
        network: NetworkManaging,
        tokenStorage: TokenStorage? = nil,
        logger: LLMLogger? = nil
    ) {
        self.displayName = displayName
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.model = model
        self.authorizationKey = authorizationKey
        self.scope = scope
        self.network = network
        self.tokenStorage = tokenStorage
        self.logger = logger
    }
    
    // MARK: - LLMProvider
    
    func complete<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type
    ) async throws -> T {
        do {
            return try await sendCompletion(system: system, user: user, as: type)
        } catch where Self.isAuthError(error) {
            // Токен мог протухнуть на стороне сервера раньше срока — сбрасываем и пробуем один раз.
            logger?.debug("GigaChat auth error — refreshing token and retrying")
            return try await sendCompletion(system: system, user: user, as: type, forceRefresh: true)
        }
    }

    private func sendCompletion<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type,
        forceRefresh: Bool = false
    ) async throws -> T {
        let token = try await getAccessToken(forceRefresh: forceRefresh)

        let url = try chatCompletionsURL()

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "stream": false,
            "repetition_penalty": 1.0
        ]

        let headers: [HTTPHeader] = [
            .contentType("application/json"),
            .authorization("Bearer \(token)")
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let parameters = Request.Parameters.body(jsonData)

        let response: GigaChatResponse = try await network.dataRequest(
            url: url,
            method: .post,
            headers: headers,
            parameters: parameters
        )

        let content = response.choices.first?.message.content ?? ""
        logger?.debug("GigaChat raw content:\n\(content)")
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.emptyResponse
        }
        return try decode(type, from: content)
    }
    
    // MARK: - Private
    
    private func chatCompletionsURL() throws -> URL {
        guard let url = URL(string: baseURL + "/api/v1/chat/completions") else {
            throw LLMError.invalidURL
        }
        return url
    }
    
    /// Запас перед истечением: обновляем токен заранее, чтобы он не протух прямо во время запроса.
    private static let expiryLeeway: TimeInterval = 60

    private func getAccessToken(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh {
            // 1. Кэш в памяти.
            if let token = accessToken,
               let expiration = tokenExpirationDate,
               expiration.timeIntervalSinceNow > Self.expiryLeeway {
                return token
            }
            // 2. Кэш в TokenStorage (переживает перезапуск приложения).
            if let stored = tokenStorage?.getToken(),
               let parsed = Self.parseStoredToken(stored),
               parsed.expiration.timeIntervalSinceNow > Self.expiryLeeway {
                accessToken = parsed.token
                tokenExpirationDate = parsed.expiration
                return parsed.token
            }
        }

        // 3. Запрашиваем новый токен.
        let fresh = try await requestAccessToken()
        accessToken = fresh.token
        tokenExpirationDate = fresh.expiration
        try? tokenStorage?.saveToken(Self.encodeStoredToken(fresh.token, expiration: fresh.expiration))
        return fresh.token
    }

    // MARK: Token persistence (токен + срок жизни в одной строке TokenStorage)

    /// JWT-токен не содержит `|`, поэтому используем его как разделитель.
    private static func encodeStoredToken(_ token: String, expiration: Date) -> String {
        "\(token)|\(expiration.timeIntervalSince1970)"
    }

    private static func parseStoredToken(_ stored: String) -> (token: String, expiration: Date)? {
        let parts = stored.split(separator: "|", maxSplits: 1)
        guard parts.count == 2, let epoch = Double(parts[1]) else { return nil }
        return (String(parts[0]), Date(timeIntervalSince1970: epoch))
    }

    /// 401/403 — признак протухшего или отозванного токена.
    private static func isAuthError(_ error: Error) -> Bool {
        if let net = error as? NetworkError, let code = net.statusCode {
            return code == 401 || code == 403
        }
        if let reqError = error as? Request.Error {
            return reqError.code == 401 || reqError.code == 403
        }
        return false
    }
    
    private func requestAccessToken() async throws -> (token: String, expiration: Date) {
        let url = try oauthURL()

        let headers: [HTTPHeader] = [
            .contentType("application/x-www-form-urlencoded"),
            .accept("application/json"),
            // Обязательный уникальный идентификатор запроса — без него OAuth вернёт 400.
            .init(name: "RqUID", value: UUID().uuidString),
            .authorization("Basic \(authorizationKey)")
        ]

        let bodyParams = "scope=\(scope)"
        let bodyData = bodyParams.data(using: .utf8)!
        let parameters = Request.Parameters.body(bodyData)

        let response: GigaChatTokenResponse = try await network.dataRequest(
            url: url,
            method: .post,
            headers: headers,
            parameters: parameters
        )

        // `expires_at` приходит в миллисекундах Unix-времени; если его нет — 30 минут.
        let expiration = response.expiresAt
            .map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
            ?? Date().addingTimeInterval(30 * 60)

        return (response.accessToken, expiration)
    }

    /// OAuth-токен выдаётся на отдельном хосте, а не на `baseURL` GigaChat.
    private func oauthURL() throws -> URL {
        guard let url = URL(string: "https://ngw.devices.sberbank.ru:9443/api/v2/oauth") else {
            throw LLMError.invalidURL
        }
        return url
    }
    
    private func decode<T: Decodable>(_ type: T.Type, from content: String) throws -> T {
        let json = content.extractedJSON()
        guard let data = json.data(using: .utf8) else {
            throw LLMError.jsonDecodingFailed(content)
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw LLMError.jsonDecodingFailed(json)
        }
    }
}

// MARK: - Response Models

private struct GigaChatResponse: Decodable {
    let choices: [GigaChatChoice]
}

private struct GigaChatChoice: Decodable {
    let message: GigaChatMessage
}

private struct GigaChatMessage: Decodable {
    let content: String
}

private struct GigaChatTokenResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresAt = "expires_at"
    }
    
    let accessToken: String
    let expiresAt: Int?
}
