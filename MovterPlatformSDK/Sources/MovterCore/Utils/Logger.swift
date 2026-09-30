//
//  Logger.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
import os.log


nonisolated public protocol LoggerProtocol: Sendable {
    nonisolated func debug(_ message: String, file: String, function: String, line: Int)
    nonisolated func info(_ message: String, file: String, function: String, line:Int)
    nonisolated func warning(_ message: String, file: String, function: String, line: Int)
    nonisolated func error(_ message: String, file: String, function: String, line:Int)
}

nonisolated public final class Logger: LoggerProtocol, @unchecked Sendable {
    private let osLog = OSLog(subsystem: "com.movter.app", category: "default")
    public init() {}
    
    nonisolated public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    nonisolated public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    nonisolated public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .default, file: file, function: function, line: line)
    }

    nonisolated public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    nonisolated private func log(_ message: String, level: OSLogType, file: String, function: String, line: Int) {
#if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: osLog, type: level, logMessage)
#endif
    }
}

//Extensions

extension LoggerProtocol {
    public nonisolated func debug(_ message: String) {
        debug(message, file: #file, function: #function, line: #line)
    }

    public nonisolated func info(_ message: String) {
        info(message, file: #file, function: #function, line: #line)
    }

    public nonisolated func warning(_ message: String) {
        warning(message, file: #file, function: #function, line: #line)
    }

    public nonisolated func error(_ message: String) {
        error(message, file: #file, function: #function, line: #line)
    }
}

