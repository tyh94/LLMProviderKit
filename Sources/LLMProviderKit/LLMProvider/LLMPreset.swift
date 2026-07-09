//
//  File.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import Foundation
import MKVNetwork

struct LLMPreset: Identifiable, Sendable, Equatable {
    let id = UUID()
    let name: String
    let displayName: String
    let baseURL: String
    let model: String
    let requiresApiKey: Bool
    let instructions: String
    let websiteURL: URL?
    let icon: String
    let additionalBodyParams: LLMProviderBodyParams
    let customHeaders: [HTTPHeader]
    let extraInfo: String?  // Дополнительная информация для отображения
    let extraInfoIcon: String?  // Иконка для дополнительной информации
    
    init(
        name: String,
        displayName: String,
        baseURL: String,
        model: String,
        requiresApiKey: Bool,
        instructions: String,
        websiteURL: URL? = nil,
        icon: String = "server.rack",
        additionalBodyParams: LLMProviderBodyParams = LLMProviderBodyParams(),
        customHeaders: [HTTPHeader] = [],
        extraInfo: String? = nil,
        extraInfoIcon: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.baseURL = baseURL
        self.model = model
        self.requiresApiKey = requiresApiKey
        self.instructions = instructions
        self.websiteURL = websiteURL
        self.icon = icon
        self.additionalBodyParams = additionalBodyParams
        self.customHeaders = customHeaders
        self.extraInfo = extraInfo
        self.extraInfoIcon = extraInfoIcon
    }
}

extension LLMPreset {
    static let ollama = LLMPreset(
        name: "ollama",
        displayName: String(localized: "llm.openai.preset.ollama", bundle: .module),
        baseURL: "http://localhost:11434",
        model: "minimax-m3:cloud",
        requiresApiKey: false,
        instructions: String(localized: "llm.openai.preset.ollama.instructions", bundle: .module),
        websiteURL: URL(string: "https://ollama.ai"),
        icon: "server.rack"
    )
    
    static let llamacpp = LLMPreset(
        name: "llamacpp",
        displayName: String(localized: "llm.openai.preset.llamacpp", bundle: .module),
        baseURL: "http://localhost:8080",
        model: "",
        requiresApiKey: false,
        instructions: String(localized: "llm.openai.preset.llamacpp.instructions", bundle: .module),
        websiteURL: URL(string: "https://github.com/ggerganov/llama.cpp"),
        icon: "server.rack"
    )
    
    static let groq = LLMPreset(
        name: "groq",
        displayName: String(localized: "llm.openai.preset.groq", bundle: .module),
        baseURL: "https://api.groq.com/openai",
        model: "llama-3.1-8b-instant",
        requiresApiKey: true,
        instructions: String(localized: "llm.openai.preset.groq.instructions", bundle: .module),
        websiteURL: URL(string: "https://console.groq.com/keys"),
        icon: "bolt.fill"
    )
    
    static let openai = LLMPreset(
        name: "openai",
        displayName: String(localized: "llm.openai.preset.openai", bundle: .module),
        baseURL: "https://api.openai.com",
        model: "gpt-4o-mini",
        requiresApiKey: true,
        instructions: String(localized: "llm.openai.preset.openai.instructions", bundle: .module),
        websiteURL: URL(string: "https://platform.openai.com/api-keys"),
        icon: "sparkles"
    )
    
    static let claude = LLMPreset(
        name: "claude",
        displayName: String(localized: "llm.openai.preset.claude", bundle: .module),
        baseURL: "https://api.anthropic.com",
        model: "claude-sonnet-4-0",
        requiresApiKey: true,
        instructions: String(localized: "llm.openai.preset.claude.instructions", bundle: .module),
        websiteURL: URL(string: "https://console.anthropic.com/keys"),
        icon: "brain.head.profile"
    )
    
    static let all: [LLMPreset] = [.ollama, .llamacpp, .groq, .openai, .claude]
}
