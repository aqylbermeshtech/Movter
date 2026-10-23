//
//  SetNotificatoinPreferencesUseCase.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation

public protocol SetNotificationPreferenceUseCase: Sendable {
    func execute(preference: NotificationPreference, isEnabled: Bool)
}
public final class DefaultSetNotificationPreferenceUseCase: SetNotificationPreferenceUseCase {
    private let repository: NotificationPreferencesRepository
    public init(repository: NotificationPreferencesRepository) {
        self.repository = repository
    }
    public func execute(preference: NotificationPreference, isEnabled: Bool) {
        repository.setEnabled(isEnabled, for: preference)
    }
}
