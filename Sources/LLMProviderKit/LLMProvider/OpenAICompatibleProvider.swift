//
//  OpenAICompatibleProvider.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import Foundation
import MKVNetwork

/// Работает с любым OpenAI-compatible сервером:
/// Ollama, llama.cpp, LM Studio, OpenAI, Groq, Together AI и т.д.
public actor OpenAICompatibleProvider: LLMProvider {
    public let displayName: String
    private let baseURL: String
    private let model: String
    private let apiKey: String?
    private let network: NetworkManaging

    /// - Parameters:
    ///   - displayName: Отображаемое имя (напр. "Ollama (локальный)")
    ///   - baseURL: Адрес сервера без trailing slash (напр. "http://192.168.1.5:11434")
    ///   - model: Имя модели (напр. "llama3.2", "mistral", "gpt-4o")
    ///   - apiKey: API-ключ (nil для локальных серверов без авторизации)
    ///   - timeoutInterval: Таймаут запроса в секундах (по умолчанию 60)
    ///   - network: Сетевой менеджер для выполнения запросов
    public init(
        displayName: String = "OpenAI Compatible",
        baseURL: String,
        model: String,
        apiKey: String? = nil,
        network: NetworkManaging
    ) {
        self.displayName = displayName
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.model = model
        self.apiKey = apiKey
        self.network = network
    }

    // MARK: - LLMProvider

    public func complete<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type
    ) async throws -> T {
        let url = try chatCompletionsURL()
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ]
        ]

        var headers: [HTTPHeader] = [
            .contentType("application/json")
        ]
        
        if let key = apiKey {
            headers.append(.authorization(bearerToken: key))
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let parameters = Request.Parameters.body(jsonData)

        let data = try await network.dataRequest(
            url: url,
            method: .post,
            headers: headers,
            parameters: parameters
        )
        
        let content = try extractContent(from: data)
        return try decode(type, from: content)
    }

    // MARK: - Private

    private func chatCompletionsURL() throws -> URL {
        guard let url = URL(string: baseURL + "/v1/chat/completions") else {
            throw LLMError.invalidURL
        }
        return url
    }

    private func extractContent(from data: Data) throws -> String {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw LLMError.emptyResponse }
        return content
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

// MARK: - Convenience initialisers for popular services

extension OpenAICompatibleProvider {
    /// OpenAI
    public static func openAI(
        apiKey: String,
        model: String = "gpt-4o-mini",
        network: NetworkManaging = NetworkManager()
    ) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "OpenAI",
            baseURL: "https://api.openai.com",
            model: model,
            apiKey: apiKey,
            network: network
        )
    }

    /// Groq (быстрый, бесплатный тариф)
    public static func groq(
        apiKey: String,
        model: String = "llama-3.1-8b-instant",
        network: NetworkManaging = NetworkManager()
    ) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "Groq",
            baseURL: "https://api.groq.com/openai",
            model: model,
            apiKey: apiKey,
            network: network
        )
    }

    /// Ollama (локальный)
    public static func ollama(
        host: String = "http://localhost:11434",
        model: String,
        network: NetworkManaging = NetworkManager()
    ) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "Ollama",
            baseURL: host,
            model: model,
            network: network
        )
    }

    /// llama.cpp server (локальный)
    public static func llamaCpp(
        host: String = "http://localhost:8080",
        model: String = "",
        network: NetworkManaging = NetworkManager()
    ) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "llama.cpp",
            baseURL: host,
            model: model,
            network: network
        )
    }
    
    /// Claude (Anthropic)
    public static func claude(
        apiKey: String,
        model: String = "claude-sonnet-4-0",
        network: NetworkManaging = NetworkManager()
    ) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "Claude",
            baseURL: "https://api.anthropic.com/v1",
            model: model,
            apiKey: apiKey,
            network: network
        )
    }
}
