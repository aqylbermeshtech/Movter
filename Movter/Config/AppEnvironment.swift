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
        switch AppEnvironment.current {
        case .debug:
            return "https://www.platform-mentor.com/api"
        case .release:
            return "https://mentor-platform-staging-staging.up.railway.app/api"
        }
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

    public var questWebURL: URL {
        let urlString: String
        switch AppEnvironment.current {
        case .debug:
            urlString = "https://mirror-quests-web-production.up.railway.app"
        case .release:
            urlString = "https://mirror-quests-web-production.up.railway.app"
        }
        guard let url = URL(string: urlString) else {
            fatalError("Invalid questWebURL: \(urlString)")
        }
        return url
    }

    public func mentorProfileShareURL(mentorId: String) -> URL? {
        let trimmed = mentorId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "https://www.platform-mentor.com/mentor/catalog/\(trimmed)")
    }

    public var appleEULAURL: URL {
        let urlString = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid appleEULAURL: \(urlString)")
        }
        return url
    }

    public var questflyWebURL: URL {
        let urlString = "https://mentor-questfly-webview-production.up.railway.app/roadmap.html"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid questflyWebURL: \(urlString)")
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
        return Bundle.main.bundleIdentifier ?? "com.mentor.app"
    }
}
