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

    public init(
        client: LLMClient,
        displayName: String? = nil,
        systemImage: String = "sparkles",
        configurationId: UUID? = nil
    ) {
        self.client = client
        self.displayName = displayName ?? client.provider.displayName
        self.systemImage = systemImage
        self.id = self.displayName
        self.configurationId = configurationId
    }
}
