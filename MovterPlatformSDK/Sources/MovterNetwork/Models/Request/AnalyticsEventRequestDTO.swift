//
//  AnalyticsEventRequestDTO.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public struct AnalyticsEventRequestDTO: Encodable, Sendable {
    /// One logical event keeps one id: a network retry must resend the same value,
    /// otherwise the backend counts a duplicate.
    public let eventId: String
    public let event: String
    public let occurredAt: String
    public let platform: String
    public let appVersion: String
    public let appBuild: String
    /// One value per app launch, not per screen.
    public let clientSessionId: String
    public let schemaVersion: Int
    public let environment: String
    public let payload: [String: String]

    private enum CodingKeys: String, CodingKey {
        case event, platform, environment, payload
        case eventId = "event_id"
        case occurredAt = "occurred_at"
        case appVersion = "app_version"
        case appBuild = "app_build"
        case clientSessionId = "client_session_id"
        case schemaVersion = "schema_version"
    }

    public init(
        eventId: String,
        event: String,
        occurredAt: String,
        platform: String,
        appVersion: String,
        appBuild: String,
        clientSessionId: String,
        schemaVersion: Int,
        environment: String,
        payload: [String: String] = [:]
    ) {
        self.eventId = eventId
        self.event = event
        self.occurredAt = occurredAt
        self.platform = platform
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.clientSessionId = clientSessionId
        self.schemaVersion = schemaVersion
        self.environment = environment
        self.payload = payload
    }
}

