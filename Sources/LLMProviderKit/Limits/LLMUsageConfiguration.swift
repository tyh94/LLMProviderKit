//
//  LLMUsageConfiguration.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 20.06.2026.
//

import Foundation

public struct LLMUsageConfiguration : Sendable {
    /// Максимум запросов за период
    let total: Int
    /// Период сброса
    let period: LLMUsagePeriod
    /// Ключ в UserDefaults
    let storageKey: String
    
    public init(
        total: Int,
        period: LLMUsagePeriod,
        storageKey: String
    ) {
        self.total = total
        self.period = period
        self.storageKey = storageKey
    }
}
