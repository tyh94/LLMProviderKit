//
//  LLMProviderType.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//


import SwiftUI

enum LLMProviderType: String, CaseIterable, Identifiable {
    case openAICompatible = "OpenAI Compatible"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .openAICompatible: return "server.rack"
        }
    }
    
    var description: String {
        switch self {
        case .openAICompatible:
            return String(localized: "llm.provider.openai.description", bundle: .module)
        }
    }
    
    var instructions: String {
        switch self {
        case .openAICompatible:
            return String(localized: "llm.provider.openai.instructions", bundle: .module)
        }
    }
}
