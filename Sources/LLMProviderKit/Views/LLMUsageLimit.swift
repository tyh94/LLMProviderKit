//
//  LLMUsageLimit.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 19.06.2026.
//

import Foundation

/// Структура для передачи информации о лимитах запросов
public struct LLMUsageLimit: Sendable {
    /// Количество использованных запросов
    public let used: Int
    /// Общий лимит запросов
    public let total: Int
    /// Дата обновления лимита (опционально)
    public let resetDate: Date?
    /// Есть ли способ получить больше запросов
    public let upgradeAvailable: Bool
    
    public init(
        used: Int,
        total: Int,
        resetDate: Date? = nil,
        upgradeAvailable: Bool = false
    ) {
        self.used = used
        self.total = total
        self.resetDate = resetDate
        self.upgradeAvailable = upgradeAvailable
    }
    
    /// Осталось запросов
    public var remaining: Int {
        max(0, total - used)
    }
    
    /// Процент использования
    public var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
    
    /// Доступны ли еще запросы
    public var hasRemaining: Bool {
        remaining > 0
    }
}
