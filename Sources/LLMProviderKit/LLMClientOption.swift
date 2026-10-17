//
//  LLMClientOption.swift
//  SourdoughCooker
//
//  Created by Татьяна Макеева on 17.06.2026.
//

import SwiftUI

/// Обёртка над LLMClient с отображаемым именем для пикера.
public struct LLMClientOption: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let systemImage: String
    public let client: LLMClient
    public let configurationId: UUID?
    /// Пояснение под названием в пикере.
    public let subtitle: String?
    /// Лимиты этого варианта, действуют все сразу; пустой список — без ограничений.
    public let usage: [LLMUsageService]
    /// Предлагать повторный разбор этим вариантом под результатом других.
    public let offersRefinement: Bool

    public init(
        client: LLMClient,
        displayName: String? = nil,
        systemImage: String = "sparkles",
        configurationId: UUID? = nil,
        subtitle: String? = nil,
        usage: [LLMUsageService] = [],
        offersRefinement: Bool = false
    ) {
        self.client = client
        self.displayName = displayName ?? client.provider.displayName
        self.systemImage = systemImage
        self.id = self.displayName
        self.configurationId = configurationId
        self.subtitle = subtitle
        self.usage = usage
        self.offersRefinement = offersRefinement
    }
}

@MainActor
extension LLMClientOption {
    /// Самый строгий из лимитов: меньше всего осталось, при равенстве — дольше ждать сброса.
    public var usageLimit: LLMUsageLimit? {
        usage.compactMap(\.currentLimit).min {
            ($0.remaining, -($0.resetDate ?? .distantFuture).timeIntervalSince1970)
                < ($1.remaining, -($1.resetDate ?? .distantFuture).timeIntervalSince1970)
        }
    }

    func recordUsage() {
        usage.forEach { $0.recordUsage() }
    }
}
