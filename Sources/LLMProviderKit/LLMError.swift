//
//  LLMError.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 16.06.2026.
//

import Foundation

public enum LLMError: LocalizedError {
    case invalidURL
    case missingCredentials
    case authenticationFailed(String)
    case networkError(Error)
    case emptyResponse
    case jsonDecodingFailed(String)
    case rateLimited
    case serverError(Int, String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid provider URL"
        case .missingCredentials:
            return "API credentials are not configured"
        case .authenticationFailed(let detail):
            return "Authentication failed: \(detail)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .emptyResponse:
            return "Empty response from LLM server"
        case .jsonDecodingFailed(let raw):
            return "Failed to decode JSON response: \(raw.prefix(200))"
        case .rateLimited:
            return "Rate limit exceeded — try again later"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        }
    }
}
