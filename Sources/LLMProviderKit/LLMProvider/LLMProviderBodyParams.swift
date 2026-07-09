//
//  LLMProviderBodyParams.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 07.07.2026.
//


import Foundation

public struct LLMProviderBodyParams: Sendable, Equatable, Codable {
    public let stream: Bool?
    public let repetitionPenalty: Double?
    public let maxTokens: Int?
    public let temperature: Double?
    public let topP: Double?
    public let frequencyPenalty: Double?
    public let presencePenalty: Double?
    public let stop: [String]?
    public let seed: Int?
    
    public init(
        stream: Bool? = nil,
        repetitionPenalty: Double? = nil,
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stop: [String]? = nil,
        seed: Int? = nil
    ) {
        self.stream = stream
        self.repetitionPenalty = repetitionPenalty
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.stop = stop
        self.seed = seed
    }
    
    enum CodingKeys: String, CodingKey {
        case stream
        case repetitionPenalty = "repetition_penalty"
        case maxTokens = "max_tokens"
        case temperature
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
        case stop
        case seed
    }
    
    public func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        return dict.compactMapValues { $0 }
    }
}
