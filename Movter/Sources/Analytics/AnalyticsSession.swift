//
//  AnalyticsSession.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

/// Identifies one app launch. The backend uses it to group events, so it must not
/// change between screens and must not be persisted across launches.
enum AnalyticsSession {
    static let id: String = UUID().uuidString
    static let schemaVersion: Int = 1
    static let platform: String = "ios"

    static var environment: String {
        AppEnvironment.current == .debug ? "staging" : "production"
    }
}
