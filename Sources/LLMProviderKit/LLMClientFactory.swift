//
//  LLMClientFactory.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import Foundation

public enum LLMClientFactory {
    public static func makeClient(
        from config: LLMClientConfiguration
    ) -> LLMClientOption {
        let client: LLMClient
        switch config.provider {
        case let .openAICompatible(displayName, baseURL, model, apiKey):
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
            displayName: config.name,
            systemImage: config.systemImage
        )
    }
}
