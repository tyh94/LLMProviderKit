//
//  OpenAICompatibleProvider.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import Foundation

/// Работает с любым OpenAI-compatible сервером:
/// Ollama, llama.cpp, LM Studio, OpenAI, Groq, Together AI и т.д.
public actor OpenAICompatibleProvider: LLMProvider {
    public let displayName: String
    private let baseURL: String
    private let model: String
    private let apiKey: String?
    private let timeoutInterval: TimeInterval

    /// - Parameters:
    ///   - displayName: Отображаемое имя (напр. "Ollama (локальный)")
    ///   - baseURL: Адрес сервера без trailing slash (напр. "http://192.168.1.5:11434")
    ///   - model: Имя модели (напр. "llama3.2", "mistral", "gpt-4o")
    ///   - apiKey: API-ключ (nil для локальных серверов без авторизации)
    ///   - timeoutInterval: Таймаут запроса в секундах (по умолчанию 60)
    public init(
        displayName: String = "OpenAI Compatible",
        baseURL: String,
        model: String,
        apiKey: String? = nil,
        timeoutInterval: TimeInterval = 60
    ) {
        self.displayName = displayName
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.model = model
        self.apiKey = apiKey
        self.timeoutInterval = timeoutInterval
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

        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = apiKey {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data = try await perform(request)
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

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200...299: break
                case 401, 403:  throw LLMError.authenticationFailed("HTTP \(http.statusCode)")
                case 429:       throw LLMError.rateLimited
                default:
                    let msg = String(data: data, encoding: .utf8) ?? ""
                    throw LLMError.serverError(http.statusCode, msg)
                }
            }
            return data
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.networkError(error)
        }
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
    public static func openAI(apiKey: String, model: String = "gpt-4o-mini") -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "OpenAI",
            baseURL: "https://api.openai.com",
            model: model,
            apiKey: apiKey
        )
    }

    /// Groq (быстрый, бесплатный тариф)
    public static func groq(apiKey: String, model: String = "llama-3.1-8b-instant") -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "Groq",
            baseURL: "https://api.groq.com/openai",
            model: model,
            apiKey: apiKey
        )
    }

    /// Ollama (локальный)
    public static func ollama(host: String = "http://localhost:11434", model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "Ollama",
            baseURL: host,
            model: model
        )
    }

    /// llama.cpp server (локальный)
    public static func llamaCpp(host: String = "http://localhost:8080", model: String = "") -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(
            displayName: "llama.cpp",
            baseURL: host,
            model: model
        )
    }
}

