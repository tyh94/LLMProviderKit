//
//  LLMProviderType.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import MKVNetwork
import SwiftUI

public enum LLMProviderType: Codable, Sendable, Identifiable {
    public static var allCases: [LLMProviderType] {
        [
            .openAICompatible(displayName: "", baseURL: "", model: "", apiKey: nil, additionalBodyParams: nil, customHeaders: nil),
            .gigaChat(displayName: "", authorizationKey: "", model: "", scope: ""),
        ]
    }

    public var id: String {
        switch self {
        case .openAICompatible: return "openAICompatible"
        case .gigaChat: return "gigaChat"
        }
    }
    
    case openAICompatible(
        displayName: String,
        baseURL: String,
        model: String,
        apiKey: String?,
        additionalBodyParams: LLMProviderBodyParams? = nil,
        customHeaders: [HTTPHeader]? = nil
    )
    
    case gigaChat(
        displayName: String,
        authorizationKey: String,
        model: String = "GigaChat",
        scope: String = "GIGACHAT_API_PERS"
    )
    
    var displayName: String {
        switch self {
        case let .openAICompatible(displayName, _, _, _, _, _):
            return displayName
        case .gigaChat(let displayName, _, _, _):
            return displayName
        }
    }
    
    var title: String {
        switch self {
        case .openAICompatible:
            return String(localized: "llm.provider.openai.title", bundle: .module)
        case .gigaChat:
            return String(localized: "llm.provider.gigachat.title", bundle: .module)
        }
    }
    
    var description: String {
        switch self {
        case .openAICompatible:
            return String(localized: "llm.provider.openai.description", bundle: .module)
        case .gigaChat:
            return String(localized: "llm.provider.gigachat.description", bundle: .module)
        }
    }
    
    var icon: String {
        switch self {
        case .openAICompatible: return "server.rack"
        case .gigaChat: return "server.rack"
        }
    }
}
