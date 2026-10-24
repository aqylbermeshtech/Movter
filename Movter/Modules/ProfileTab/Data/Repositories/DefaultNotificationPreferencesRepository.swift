//
//  DefaultNotificationPreferencesRepository.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation
import UIKit
import UserNotifications
public final class DefaultNotificationPreferencesRepository: NotificationPreferencesRepository {
    private let defaults: UserDefaults
    private let notificationCenter: UNUserNotificationCenter
    private let keyPrefix = "notification_preference_"
    public init(
        defaults: UserDefaults = .standard,
        notificationCenter: UNUserNotificationCenter = .current()
    ) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
    }
    public func isEnabled(_ preference: NotificationPreference) -> Bool {
        let key = keyPrefix + preference.rawValue
        guard defaults.object(forKey: key) != nil else { return preference.defaultValue }
        return defaults.bool(forKey: key)
    }
    public func setEnabled(_ isEnabled: Bool, for preference: NotificationPreference) {
        defaults.set(isEnabled, forKey: keyPrefix + preference.rawValue)
    }
    public func getAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .ephemeral: return .temporary
        @unknown default: return .unknown
        }
    }
    public func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    @MainActor
    public func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
