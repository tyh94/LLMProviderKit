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
        network: NetworkManaging,
        tokenStorage: LLMTokenFactory,
        logger: LLMLogger? = nil
    ) -> LLMClientOption {
        config.makeClientOption(
            network: network,
            tokenStorage: tokenStorage,
            logger: logger
        )
    }
}
