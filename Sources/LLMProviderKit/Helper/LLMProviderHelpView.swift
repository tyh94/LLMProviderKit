//
//  LLMProviderHelpView.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//

import SwiftUI

struct LLMProviderHelpView: View {
    let preset: LLMPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: preset.icon)
                    .foregroundStyle(.tint)
                Text(preset.displayName)
                    .font(.headline)
            }
            
            Text(preset.instructions)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let extraInfo = preset.extraInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text(extraInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let icon = preset.extraInfoIcon {
                        Label(
                            String(localized: "llm.openai.preset.extra.note", bundle: .module),
                            systemImage: icon
                        )
                        .font(.caption)
                        .foregroundStyle(.tint)
                    }
                }
                .padding(.top, 4)
            }
            
            if let url = preset.websiteURL {
                Link(
                    String(localized: "llm.openai.preset.get.key", bundle: .module),
                    destination: url
                )
                .font(.subheadline)
                .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LLMProviderHelpView(preset: .openai)
    }
}
