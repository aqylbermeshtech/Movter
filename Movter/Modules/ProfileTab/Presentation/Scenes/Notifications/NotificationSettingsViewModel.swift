//
//  NotificationSettingsViewModel.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation

@MainActor
public final class NotificationSettingsViewModel {

    // MARK: - State

    public private(set) var authorizationStatus: NotificationAuthorizationStatus = .notDetermined
    public private(set) var items: [(preference: NotificationPreference, isEnabled: Bool)] = []

    public var onStateChange: (() -> Void)?

    public var isAuthorized: Bool {
        authorizationStatus.isAuthorized
    }

    public var statusText: String {
        switch authorizationStatus {
        case .authorized, .temporary: return "Allowed"
        case .denied: return "Blocked in Settings"
        case .notDetermined: return "Not enabled"
        case .unknown: return "Unknown"
        }
    }

    public var permissionFooterText: String {
        switch authorizationStatus {
        case .notDetermined: return "Tap to let Movter send notifications."
        case .denied: return "Notifications are turned off for Movter. Tap to open Settings."
        default: return "These choices only apply while notifications are allowed."
        }
    }

    // MARK: - Dependencies

    private let getPreferencesUseCase: GetNotificationPreferencesUseCase
    private let setPreferenceUseCase: SetNotificationPreferenceUseCase
    private let permissionUseCase: RequestNotificationPermissionUseCase

    public init(
        getPreferencesUseCase: GetNotificationPreferencesUseCase,
        setPreferenceUseCase: SetNotificationPreferenceUseCase,
        permissionUseCase: RequestNotificationPermissionUseCase
    ) {
        self.getPreferencesUseCase = getPreferencesUseCase
        self.setPreferenceUseCase = setPreferenceUseCase
        self.permissionUseCase = permissionUseCase
    }

    // MARK: - Actions

    public func loadData() async {
        let (status, preferences) = await getPreferencesUseCase.execute()
        self.authorizationStatus = status
        self.items = preferences
        onStateChange?()
    }

    public func togglePreference(at index: Int, isEnabled: Bool) {
        guard items.indices.contains(index) else { return }
        let pref = items[index].preference
        items[index].isEnabled = isEnabled
        setPreferenceUseCase.execute(preference: pref, isEnabled: isEnabled)
        onStateChange?()
    }

    public func handlePermissionTap() async {
        switch authorizationStatus {
        case .notDetermined:
            _ = try? await permissionUseCase.requestAuthorization()
            await loadData()
        default:
            permissionUseCase.openSettings()
        }
    }
}
