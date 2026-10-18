//
//  LLMInputReport.swift
//  LLMProviderKit
//

import Foundation

/// What the user sends to the developer from `LLMInputView`: the pasted text, who parsed it and how it went.
public struct LLMInputReport<Result> {
    public enum Outcome {
        /// Parsed, but the result is wrong.
        case wrong(Result)
        /// Parsing failed with this message.
        case failed(String)
    }

    public let input: String
    public let provider: String
    public let outcome: Outcome
}
