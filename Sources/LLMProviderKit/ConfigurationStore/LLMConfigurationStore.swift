//
//  LLMConfigurationStore.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import Foundation

public protocol LLMConfigurationStore: Sendable {
    func load() async throws -> [LLMClientConfiguration]
    func save(_ configurations: [LLMClientConfiguration]) async throws
}

public struct LLMConfigurationStoreMock: LLMConfigurationStore {
    let configs: [LLMClientConfiguration]
    
    public init(configs: [LLMClientConfiguration] = []) {
        self.configs = configs
    }
    
    public func load() async throws -> [LLMClientConfiguration] {
        configs
    }
    
    public func save(_ configurations: [LLMClientConfiguration]) async throws {}
}
