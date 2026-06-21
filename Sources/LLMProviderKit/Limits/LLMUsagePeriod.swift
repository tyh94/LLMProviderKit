//
//  LLMUsagePeriod.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 20.06.2026.
//

import Foundation

public enum LLMUsagePeriod: Codable, Sendable {
    case daily
    case weekly
    case monthly
    case never

    func nextResetDate(from date: Date = .now) -> Date? {
        var cal = Calendar.current
        cal.timeZone = .current
        switch self {
        case .daily:
            return cal.startOfDay(for: date + 86400)
        case .weekly:
            var c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            c.weekOfYear! += 1
            return cal.date(from: c)
        case .monthly:
            var c = cal.dateComponents([.year, .month], from: date)
            c.month! += 1; c.day = 1
            return cal.date(from: c)
        case .never:
            return nil
        }
    }
}
