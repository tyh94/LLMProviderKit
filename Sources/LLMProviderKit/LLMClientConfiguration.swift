//
//  LLMClientConfiguration.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import SwiftUI

public struct LLMClientConfiguration: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var systemImage: String
    public var provider: Provider
    
    public init(
        id: UUID = UUID(),
        name: String,
        systemImage: String = "sparkles",
        provider: Provider
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.provider = provider
    }
}

extension LLMClientConfiguration {
    public enum Provider: Codable, Sendable {
        case openAICompatible(
            displayName: String,
            baseURL: String,
            model: String,
            apiKey: String?
        )
    }
    
    public enum YandexModel: Codable, Sendable {
        case lite
        case pro
        case custom(String)
    }
}

extension LLMClientConfiguration {
    public func makeClientOption() -> LLMClientOption {
        let client: LLMClient
        switch provider {
        case let .openAICompatible(
            displayName,
            baseURL,
            model,
            apiKey
        ):
            client = LLMClient(
                provider: OpenAICompatibleProvider(
                    displayName: displayName,
                    baseURL: baseURL,
                    model: model,
                    apiKey: apiKey
                )
            )
        }
        
        return LLMClientOption(
            client: client,
            displayName: name,
            systemImage: systemImage
        )
    }
}
