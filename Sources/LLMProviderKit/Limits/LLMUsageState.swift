//
//  LLMUsageState.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 20.06.2026.
//

import Foundation

struct LLMUsageState: Codable {
    var used: Int = 0
    var resetDate: Date?
}
