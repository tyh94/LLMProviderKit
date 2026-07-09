//
//  OpenAICompatibleProvider.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import Foundation
import MKVNetwork

/// Работает с любым OpenAI-compatible сервером:
/// Ollama, llama.cpp, LM Studio, OpenAI, Groq, Together AI, GigaChat и т.д.
actor OpenAICompatibleProvider: LLMProvider {
    public let displayName: String
    private let baseURL: String
    private let model: String
    private let apiKey: String?
    private let network: NetworkManaging
    private let additionalBodyParams: LLMProviderBodyParams
    private let customHeaders: [HTTPHeader]
    private let logger: LLMLogger?

    /// - Parameters:
    ///   - displayName: Отображаемое имя (напр. "Ollama (локальный)")
    ///   - baseURL: Адрес сервера без trailing slash (напр. "http://192.168.1.5:11434")
    ///   - model: Имя модели (напр. "llama3.2", "mistral", "gpt-4o")
    ///   - apiKey: API-ключ (nil для локальных серверов без авторизации)
    ///   - network: Сетевой менеджер для выполнения запросов
    ///   - additionalBodyParams: Дополнительные параметры тела запроса
    ///   - customHeaders: Кастомные заголовки
    init(
        displayName: String = "OpenAI Compatible",
        baseURL: String,
        model: String,
        apiKey: String? = nil,
        network: NetworkManaging,
        additionalBodyParams: LLMProviderBodyParams = LLMProviderBodyParams(),
        customHeaders: [HTTPHeader] = [],
        logger: LLMLogger?
    ) {
        self.displayName = displayName
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.model = model
        self.apiKey = apiKey
        self.network = network
        self.additionalBodyParams = additionalBodyParams
        self.customHeaders = customHeaders
        self.logger = logger
    }
    
    /// Удобный инициализатор из пресета
    init(
        preset: LLMPreset,
        apiKey: String? = nil,
        network: NetworkManaging,
        logger: LLMLogger?
    ) {
        self.init(
            displayName: preset.displayName,
            baseURL: preset.baseURL,
            model: preset.model,
            apiKey: apiKey,
            network: network,
            additionalBodyParams: preset.additionalBodyParams,
            customHeaders: preset.customHeaders,
            logger: logger
        )
    }

    // MARK: - LLMProvider

    func complete<T: Decodable & Sendable>(
        system: String,
        user: String,
        as type: T.Type
    ) async throws -> T {
        let url = try chatCompletionsURL()
        
        // Формируем базовое тело запроса
        var body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ]
        ]
        
        // Добавляем дополнительные параметры из LLMProviderBodyParams
        let additionalParams = additionalBodyParams.toDictionary()
        for (key, value) in additionalParams {
            body[key] = value
        }

        var headers: [HTTPHeader] = [
            .contentType("application/json")
        ]
        
        if let key = apiKey {
            headers.append(.authorization(bearerToken: key))
        }
        
        // Добавляем кастомные заголовки
        headers.append(contentsOf: customHeaders)

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
