//
//  Logger.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
import os.log


public protocol LoggerProtocol {
    func debug(_ message: String, file: String, function: String, line: Int)
    func info(_ message: String, file: String, function: String, line:Int)
    func warning(_ message: String, file: String, function: String, line: Int)
    func error(_ message: String, file: String, function: String, line:Int)
}

public final class Logger: LoggerProtocol {
    private let osLog = OSLog(subsystem: "com.movter.app", category: "default")
    public init() {}
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .default, file: file, function: function, line: line)
    }

    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    private func log(_ message: String, level: OSLogType, file: String, function: String, line: Int) {
#if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: osLog, type: level, logMessage)
#endif
    }
}

//Extensions

extension LoggerProtocol {
    public func debug(_ message: String) {
        debug(message, file: #file, function: #function, line: #line)
    }

    public func info(_ message: String) {
        info(message, file: #file, function: #function, line: #line)
    }

    public func warning(_ message: String) {
        warning(message, file: #file, function: #function, line: #line)
    }

    public func error(_ message: String) {
        error(message, file: #file, function: #function, line: #line)
    }
}

