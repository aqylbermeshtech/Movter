//
//  GetNotificationPreferencesUseCase.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation

public protocol GetNotificationPreferencesUseCase: Sendable {
    func execute() async -> (status: NotificationAuthorizationStatus, preferences: [(preference: NotificationPreference, isEnabled: Bool)])
}
public final class DefaultGetNotificationPreferencesUseCase: GetNotificationPreferencesUseCase {
    private let repository: NotificationPreferencesRepository
    public init(repository: NotificationPreferencesRepository) {
        self.repository = repository
    }
    public func execute() async -> (status: NotificationAuthorizationStatus, preferences: [(preference: NotificationPreference, isEnabled: Bool)]) {
        let status = await repository.getAuthorizationStatus()
        let preferences = NotificationPreference.allCases.map { pref in
            (preference: pref, isEnabled: repository.isEnabled(pref))
        }
        return (status, preferences)
    }
}
