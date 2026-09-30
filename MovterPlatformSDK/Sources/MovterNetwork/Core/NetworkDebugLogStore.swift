//
//  NetworkDebugLogStore.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

/// Collects HTTP request/response logs in debug builds for diagnostic screens.
/// Thread-safe via NSLock; only compiled and used under `#if DEBUG`.
#if DEBUG
nonisolated final class NetworkDebugLogStore: @unchecked Sendable {
    static let shared = NetworkDebugLogStore()

    private var logs: [String] = []
    private let lock = NSLock()
    private let maxEntries = 500

    private init() {}

    func append(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        if logs.count >= maxEntries {
            logs.removeFirst()
        }
        logs.append(message)
    }

    var allLogs: [String] {
        lock.lock()
        defer { lock.unlock() }
        return logs
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        logs.removeAll()
    }
}
#endif
