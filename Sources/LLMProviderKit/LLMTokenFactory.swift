//
//  LLMTokenFactory.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import Foundation
import MKVNetwork
import Storage

public typealias LLMTokenFactory = Factory<LLMProviderType, TokenStorage>

public extension LLMTokenFactory {
    convenience init(keyStorage: KeyValueStorage) {
        self.init { provider in
            switch provider {
            case let .openAICompatible(displayName, baseURL, model, _, _, _):
                let key = "openai_token_\(displayName)_\(baseURL)_\(model)".lowercased()
                return LLMTokenFactoryService(
                    key: key,
                    storage: keyStorage
                )
                
            case let .gigaChat(displayName, _, model, scope):
                let key = "gigachat_token_\(displayName)_\(model)_\(scope)".lowercased()
                return LLMTokenFactoryService(
                    key: key,
                    storage: keyStorage
                )
            }
        }
    }
}
public struct LLMTokenFactoryService: TokenStorage {
    private let key: String
    private let storage: KeyValueStorage
    
    public init(key: String, storage: KeyValueStorage) {
        self.key = key
        self.storage = storage
    }
    
    public func getToken() -> String? {
        try? storage.object(forKey: key)
    }
    
    public func saveToken(_ token: String) throws {
        try storage.set(token, forKey: key)
    }
    
    public func removeToken() throws {
        try storage.removeObject(forKey: key)
    }
}
