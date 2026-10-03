//
//  AccessTokenStore.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
//import MovterCore


public final class AccessTokenStore {
    public static let shared = AccessTokenStore()
    
    private enum Keys {
        static let accessToken = "auth_access_token"
        static let refreshToken = "auth_refresh_token"
        static let tokenExpiresAt = "auth_token_expires_at"
        static let timeFromLastTokenUpdate = "auth_time_from_last_token_update"
        static let profileBootstrapPending = "auth_profile_bootstrap_pending"
    }
    
    private var storage: StorageProtocol? {
        DIContainer.shared.resolve(StorageProtocol.self)
    }

    private init() {}

    public var accessToken: String? {
        get { try? storage?.loadString(for: Keys.accessToken) }
        set {
            if let newValue {
                try? storage?.saveString(newValue, for: Keys.accessToken)
            } else {
                try? storage?.deleteSecure(for: Keys.accessToken)
            }
        }
    }

    public var refreshToken: String? {
        get { try? storage?.loadString(for: Keys.refreshToken) }
        set {
            if let newValue {
                try? storage?.saveString(newValue, for: Keys.refreshToken)
            } else {
                try? storage?.deleteSecure(for: Keys.refreshToken)
            }
        }
    }

    public var tokenExpiresAt: Double? {
        get {
            guard let string = storage?.load(for: Keys.tokenExpiresAt) as? String else { return nil }
            return Double(string)
        }
        set {
            if let newValue {
                storage?.save(String(newValue), for: Keys.tokenExpiresAt)
            } else {
                storage?.delete(for: Keys.tokenExpiresAt)
            }
        }
    }

    public var timeFromLastTokenUpdate: Double? {
        get {
            guard let string = storage?.load(for: Keys.timeFromLastTokenUpdate) as? String else { return nil }
            return Double(string)
        }
        set {
            if let newValue {
                storage?.save(String(newValue), for: Keys.timeFromLastTokenUpdate)
            } else {
                storage?.delete(for: Keys.timeFromLastTokenUpdate)
            }
        }
    }

    public var userIsAuthorized: Bool {
        accessToken != nil && refreshToken != nil
    }

    public var activeRoleInAccessToken: String? {
        guard let token = accessToken else { return nil }
        return AccessTokenJWTActiveRole.persistedAppRoleRaw(from: token)
    }

    public var userIdInAccessToken: String? {
        guard let token = accessToken else { return nil }
        return AccessTokenJWTSubject.userId(from: token)
    }

    public var isProfileBootstrapPending: Bool {
        get {
            UserDefaults.standard.object(forKey: Keys.profileBootstrapPending) as? Bool ?? false
        }
        set {
            if newValue {
                UserDefaults.standard.set(true, forKey: Keys.profileBootstrapPending)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.profileBootstrapPending)
            }
        }
    }

    public func saveTokens(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiresAt = Date().timeIntervalSince1970 + Double(expiresIn)
        self.timeFromLastTokenUpdate = Date().timeIntervalSince1970
        syncPersistedUserRoleFromCurrentAccessToken()
    }

    public func syncPersistedUserRoleFromCurrentAccessToken() {
        guard let token = accessToken,
              let role = AccessTokenJWTActiveRole.persistedAppRoleRaw(from: token) else {
            return
        }
        UserDefaults.standard.set(role, forKey: MovterAppStoredUserDefaultsKey.persistedUserRoleRawValue)
    }

    public func clear() {
        accessToken = nil
        refreshToken = nil
        tokenExpiresAt = nil
        timeFromLastTokenUpdate = nil
        UserDefaults.standard.removeObject(forKey: Keys.profileBootstrapPending)
        UserDefaults.standard.removeObject(forKey: MovterAppStoredUserDefaultsKey.persistedUserRoleRawValue)
    }

    public func clearAndNotifySessionInvalidated() {
        clear()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.sessionInvalidatedNotification, object: nil)
        }
    }

    public static let sessionInvalidatedNotification = Notification.Name("SessionInvalidated")

    public func shouldRefreshProactively(thresholdSeconds: TimeInterval = 300) -> Bool {
        guard let expiresAt = tokenExpiresAt else { return false }
        let now = Date().timeIntervalSince1970
        return now >= expiresAt - thresholdSeconds
    }
}
