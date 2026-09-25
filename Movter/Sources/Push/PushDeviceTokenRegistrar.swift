//
//  PushDeviceTokenRegistrar.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
import OSLog
//import MentorDomain
//import MentorNetwork
//import MentorStorage

enum PushDeviceTokenRegistrar {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mentorapp.mentor", category: "PushToken")
    private static let lastSentTokenKey = "mentor.push.lastRegisteredFcmToken"
    private static var lastBecomeActiveForcedSyncWallClock: TimeInterval = 0
    private static let minBecomeActiveForcedSyncIntervalSeconds: TimeInterval = 45

    private static var useCase: RegisterPushDeviceTokenUseCaseProtocol {
        UseCaseBuilder.shared.makeRegisterPushDeviceTokenUseCase()
    }

    static func syncRegistrationOnAppBecameActiveIfNeeded() async {
        let trimmed = MentorPushNotificationRuntime.lastFCMToken?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, AccessTokenStore.shared.userIsAuthorized else { return }

        let now = Date().timeIntervalSince1970
        let elapsed = now - lastBecomeActiveForcedSyncWallClock
        guard lastBecomeActiveForcedSyncWallClock == 0
            || elapsed >= minBecomeActiveForcedSyncIntervalSeconds else { return }

        lastBecomeActiveForcedSyncWallClock = now
        await registerWithBackendIfAuthenticated(fcmToken: trimmed, bypassSentTokenDedup: true)
    }

    static func registerWithBackendIfAuthenticated(fcmToken: String, bypassSentTokenDedup: Bool = false) async {
        let trimmed = fcmToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard AccessTokenStore.shared.userIsAuthorized else { return }
        if !bypassSentTokenDedup, UserDefaults.standard.string(forKey: lastSentTokenKey) == trimmed {
            return
        }
        do {
            try await useCase.execute(fcmToken: trimmed, platform: "ios")
            UserDefaults.standard.set(trimmed, forKey: lastSentTokenKey)
            let host = NetworkConfiguration.notificationServiceBaseURL?.host
                ?? NetworkConfiguration.shared.baseURL.host
            log.info("Registered FCM push token with backend; host=\(host ?? "?")")
            #if DEBUG
            print("[Push] register token OK → \(host ?? "?")")
            #endif
        } catch {
            log.warning("Push token backend registration failed: \(error.localizedDescription)")
            #if DEBUG
            print("[Push] register token failed: \(error.localizedDescription)")
            #endif
        }
    }

    static func clearRegistrationState() {
        UserDefaults.standard.removeObject(forKey: lastSentTokenKey)
    }

    static func clearLastRegisteredTokenForTests() {
        UserDefaults.standard.removeObject(forKey: lastSentTokenKey)
    }
}

