//
//  LLMUsageConfiguration.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 20.06.2026.
//

import Foundation

public struct LLMUsageConfiguration: Sendable {
    /// Максимум запросов за период
    public let total: Int
    /// Период сброса
    public let period: LLMUsagePeriod
    /// Ключ в UserDefaults
    public let storageKey: String
    public let canUpgrade: Bool
    
    public init(
        total: Int,
        period: LLMUsagePeriod,
        storageKey: String,
        canUpgrade: Bool
    ) {
        self.total = total
        self.period = period
        self.storageKey = storageKey
        self.canUpgrade = canUpgrade
    }
}
