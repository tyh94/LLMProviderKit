//
//  LLMClientService.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 18.06.2026.
//

import Observation
import Foundation
import MKVNetwork

@Observable
@MainActor
public final class LLMClientService {
    public private(set) var configurations: [LLMClientConfiguration] = []

    public var clients: [LLMClientOption] {
        localClients + configurations.map {
            LLMClientFactory.makeClient(from: $0, network: network, tokenStorage: tokenStorage, logger: logger)
        }
    }

    private let localClients: [LLMClientOption]
    private let store: any LLMConfigurationStore
    private let network: any NetworkManaging
    private let tokenStorage: LLMTokenFactory
    private let logger: LLMLogger?

    public init(
        localClients: [LLMClientOption],
        store: any LLMConfigurationStore,
        network: any NetworkManaging,
        tokenStorage: LLMTokenFactory,
        logger: LLMLogger? = nil
    ) {
        self.localClients = localClients
        self.store = store
        self.network = network
        self.tokenStorage = tokenStorage
        self.logger = logger
    }

    public func load() async throws {
        configurations = try await store.load()
    }

    public func add(
        _ configuration: LLMClientConfiguration
    ) async throws {
        configurations.append(configuration)
        try await persist()
    }

    public func remove(
        id: UUID
    ) async throws {
        configurations.removeAll { $0.id == id }
        try await persist()
    }

    public func update(
        _ configuration: LLMClientConfiguration
    ) async throws {
        guard let index = configurations.firstIndex(where: {
            $0.id == configuration.id
        }) else {
            return
        }

        configurations[index] = configuration
        try await persist()
    }

    private func persist() async throws {
        try await store.save(configurations)
    }
}
