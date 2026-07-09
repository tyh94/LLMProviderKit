//
//  LLMLogger.swift
//  LLMProviderKit
//
//  Created by Татьяна Макеева on 08.07.2026.
//

import Foundation

public enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

public protocol LLMLogger: Sendable {
    func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    )
}

extension LLMLogger {
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    public func error(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(error.localizedDescription, level: .error, file: file, function: function, line: line)
    }
}
