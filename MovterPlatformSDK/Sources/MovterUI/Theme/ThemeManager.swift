//
//  ThemeManager.swift
//  MovterUI
//
//  Created by Nurtore on 02.07.2026.
//

import UIKit

public enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    public var displayName: String {
        switch self {
        case .system: return "Automatic"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

public final class ThemeManager {
    public static let shared = ThemeManager()

    public static let themeDidChangeNotification = Notification.Name("ThemeDidChangeNotification")

    private let themeKey = "selected_app_theme"

    public private(set) var currentTheme: AppTheme = .system

    private init() {
        if let savedRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedRaw) {
            self.currentTheme = savedTheme
        }
    }

    public func selectTheme(_ theme: AppTheme) {
        self.currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        applyToConnectedScenes()

        NotificationCenter.default.post(name: ThemeManager.themeDidChangeNotification, object: nil)
    }

    public func apply(to window: UIWindow) {
        window.overrideUserInterfaceStyle = currentTheme.userInterfaceStyle
        window.tintColor = .accent
    }

    public func applyToConnectedScenes() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { apply(to: $0) }
    }
}
