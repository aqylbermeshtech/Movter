//
//  AppEnvironment.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

public enum AppEnvironment {
    case debug
    case release

    public static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}

public struct AppConfiguration {
    public static let shared = AppConfiguration()

    private init() {}

    // MARK: - API Configuration

    public var baseURL: String {
        return "https://api.themoviedb.org/3"
    }

    public var baseURLAsURL: URL {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid baseURL: \(baseURL)")
        }
        return url
    }

    public var notificationServiceBaseURL: URL? {
        nil
    }

    public var networkTimeout: TimeInterval {
        return 30.0
    }

    // MARK: - External Services

    public var appleEULAURL: URL {
        let urlString = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid appleEULAURL: \(urlString)")
        }
        return url
    }

    // MARK: - Feature Flags

    public var isLoggingEnabled: Bool {
        return AppEnvironment.current == .debug
    }

    public var isDebugMenuEnabled: Bool {
        return AppEnvironment.current == .debug
    }

    public var isMockDataEnabled: Bool {
        return AppEnvironment.current == .debug
    }

    public var isAnalyticsEnabled: Bool {
        return AppEnvironment.current == .release
    }

    // MARK: - App Information

    public var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    public var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "kz.movter.app"
    }
}
