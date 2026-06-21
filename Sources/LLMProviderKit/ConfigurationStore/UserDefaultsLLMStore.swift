//
//  UserDefaultsLLMStore.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import Foundation
import Storage

public final class KeyValueStorageLLMStore: LLMConfigurationStore {
    private let storage: KeyValueStorage
    private let key: String

    public init(
        storage: KeyValueStorage = UserDefaultsStorage(),
        key: String = "llm.clients"
    ) {
        self.storage = storage
        self.key = key
    }

    public func load() async throws -> [LLMClientConfiguration] {
        try storage.object(forKey: key) ?? []
    }

    public func save(
        _ configurations: [LLMClientConfiguration]
    ) async throws {
        try storage.set(configurations, forKey: key)
    }
}
