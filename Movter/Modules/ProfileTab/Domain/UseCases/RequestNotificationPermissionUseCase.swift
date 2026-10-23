//
//  RequestNotificationPermissionUseCase.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import Foundation

public protocol RequestNotificationPermissionUseCase: Sendable {
    func requestAuthorization() async throws -> Bool
    @MainActor func openSettings()
}
public final class DefaultRequestNotificationPermissionUseCase: RequestNotificationPermissionUseCase {
    private let repository: NotificationPreferencesRepository
    public init(repository: NotificationPreferencesRepository) {
        self.repository = repository
    }
    public func requestAuthorization() async throws -> Bool {
        try await repository.requestAuthorization()
    }
    @MainActor
    public func openSettings() {
        repository.openSystemSettings()
    }
}
