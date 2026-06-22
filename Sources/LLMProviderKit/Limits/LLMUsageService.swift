//
//  LLMUsageService.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 19.06.2026.
//

import Foundation
import Observation
import Storage

@Observable
@MainActor
public final class LLMUsageService {
    public private(set) var currentLimit: LLMUsageLimit?

    public var isExceeded: Bool {
        currentLimit?.hasRemaining == false
    }

    private let storage: KeyValueStorage
    private let configuration: LLMUsageConfiguration
    private var state = LLMUsageState()

    public init(
        configuration: LLMUsageConfiguration,
        storage: KeyValueStorage = UserDefaultsStorage()
    ) {
        self.storage = storage
        self.configuration = configuration
        loadState()
        resetIfNeeded()
        refreshLimit()
    }

    public func recordUsage() {
        resetIfNeeded()
        state.used += 1
        saveState()
        refreshLimit()
    }

    public func reset() {
        state.used = 0
        state.resetDate = configuration.period.nextResetDate()
        saveState()
        refreshLimit()
    }

    private func resetIfNeeded() {
        guard let resetDate = state.resetDate,
              Date.now >= resetDate
        else { return }

        state.used = 0
        state.resetDate = configuration.period.nextResetDate()
        saveState()
    }

    private func refreshLimit() {
        currentLimit = LLMUsageLimit(
            used: state.used,
            total: configuration.total,
            resetDate: state.resetDate,
            upgradeAvailable: configuration.canUpgrade
        )
    }

    private var storageKey: String {
        configuration.storageKey
    }

    private func saveState() {
        try? storage.set(state, forKey: storageKey)
    }

    private func loadState() {
        guard
            let saved: LLMUsageState = try? storage.object(forKey: storageKey)
        else {
            state.resetDate = configuration.period.nextResetDate()
            return
        }
        state = saved
        if state.resetDate == nil {
            state.resetDate = configuration.period.nextResetDate()
        }
    }
}
