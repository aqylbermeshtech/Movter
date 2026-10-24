//
//  NotificationPreferencesRepository.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation

public protocol NotificationPreferencesRepository: Sendable {
    func isEnabled(_ preference: NotificationPreference) -> Bool
    func setEnabled(_ isEnabled: Bool, for preference: NotificationPreference)
    func getAuthorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    @MainActor func openSystemSettings()
}
