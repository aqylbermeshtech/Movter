//
//  ThemeManager.swift
//  Movter
//
//  Created by Nurtore on 02.07.2026.
//

import UIKit

/// Which appearance the app runs in. That is the whole of the theme setting — the
/// palette itself lives in the dynamic colours on `UIColor`, which resolve off whatever
/// interface style this produces, so no screen has to ask which theme is current.
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    /// `.unspecified` is what hands the choice back to iOS.
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: return "Automatic"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

final class ThemeManager {
    static let shared = ThemeManager()

    static let themeDidChangeNotification = Notification.Name("ThemeDidChangeNotification")

    private let themeKey = "selected_app_theme"

    /// Follow the device unless the user has said otherwise. A value saved by an older
    /// build names an accent that no longer exists, so it fails to parse and lands here.
    private(set) var currentTheme: AppTheme = .system

    private init() {
        if let savedRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedRaw) {
            self.currentTheme = savedTheme
        }
    }

    func selectTheme(_ theme: AppTheme) {
        self.currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        applyToConnectedScenes()

        NotificationCenter.default.post(name: ThemeManager.themeDidChangeNotification, object: nil)
    }

    /// Overriding the window's style is what makes the choice visible: every dynamic
    /// colour below resolves against it, and UIKit re-renders the tree for free.
    func apply(to window: UIWindow) {
        window.overrideUserInterfaceStyle = currentTheme.userInterfaceStyle
        window.tintColor = .accent
    }

    func applyToConnectedScenes() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { apply(to: $0) }
    }
}
