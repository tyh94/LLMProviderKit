//
//  LLMClientConfiguration.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import MKVNetwork
import SwiftUI

public struct LLMClientConfiguration: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var systemImage: String
    public var provider: LLMProviderType
    
    public init(
        id: UUID = UUID(),
        name: String,
        systemImage: String = "sparkles",
        provider: LLMProviderType
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.provider = provider
    }
}

extension LLMClientConfiguration {
    public func makeClientOption(
        network: any NetworkManaging,
        tokenStorage: LLMTokenFactory,
        logger: LLMLogger? = nil
    ) -> LLMClientOption {
        let client: LLMClient
        switch provider {
        case let .openAICompatible(
            displayName,
            baseURL,
            model,
            apiKey,
            additionalBodyParams,
            customHeaders
        ):
            client = LLMClient(
                provider: OpenAICompatibleProvider(
                    displayName: displayName,
                    baseURL: baseURL,
                    model: model,
                    apiKey: apiKey,
                    network: network,
                    additionalBodyParams: additionalBodyParams ?? LLMProviderBodyParams(),
                    customHeaders: customHeaders ?? [],
                    logger: logger
                )
            )
            
        case let .gigaChat(
            displayName,
            authorizationKey,
            model,
            scope
        ):
            // GigaChat требует отдельную сессию с доверием к корню Минцифры,
            // поэтому не используем общий `network`.
            client = LLMClient(
                provider: GigaChatProvider(
                    displayName: displayName,
                    model: model,
                    authorizationKey: authorizationKey,
                    scope: scope,
                    network: NetworkManager.gigaChat(logger: logger),
                    tokenStorage: tokenStorage.make(provider),
                    logger: logger
                )
            )
        }
        
        return LLMClientOption(
            client: client,
            displayName: name,
            systemImage: systemImage,
            configurationId: id
        )
    }
}

