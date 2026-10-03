//
//  AnalyticsEnvelope.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

/// Builds the request once so a retry reuses the same `event_id` and timestamp.
enum AnalyticsEnvelope {
    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func make(name: String, payload: [String: String], occurredAt: Date = Date()) -> AnalyticsEventRequestDTO {
        AnalyticsEventRequestDTO(
            eventId: UUID().uuidString,
            event: name,
            occurredAt: timestampFormatter.string(from: occurredAt),
            platform: AnalyticsSession.platform,
            appVersion: AppConfiguration.shared.appVersion,
            appBuild: AppConfiguration.shared.buildNumber,
            clientSessionId: AnalyticsSession.id,
            schemaVersion: AnalyticsSession.schemaVersion,
            environment: AnalyticsSession.environment,
            payload: payload
        )
    }
}
