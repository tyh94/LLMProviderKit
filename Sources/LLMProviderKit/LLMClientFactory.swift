//
//  LLMClientFactory.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import Foundation
import MKVNetwork

public enum LLMClientFactory {
    public static func makeClient(
        from config: LLMClientConfiguration,
        network: NetworkManaging
    ) -> LLMClientOption {
        let client: LLMClient
        switch config.provider {
        case let .openAICompatible(displayName, baseURL, model, apiKey):
            client = LLMClient(
                provider: OpenAICompatibleProvider(
                    displayName: displayName,
                    baseURL: baseURL,
                    model: model,
                    apiKey: apiKey,
                    network: network
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
