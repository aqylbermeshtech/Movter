//
//  UIColor+Theme.swift
//  MovterUI
//
//  Created by Nurtore on 22.03.2026.
//

import UIKit

public extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

public extension UIColor {

    // MARK: - Neutral ramp
    static let canvas        = adaptive(light: "FFFFFF", dark: "0A0A0B")

    static let surface       = adaptive(light: "F2F2F7", dark: "151517")

    static let hairline      = adaptive(light: "D7D7DC", dark: "2A2A2E")

    static let textPrimary   = adaptive(light: "1C1C1E", dark: "F5F5F7")

    static let textSecondary = adaptive(light: "6C6C70", dark: "8A8A8F")

    static let destructive   = adaptive(light: "C0453A", dark: "D96A5A")

    static let accent        = adaptive(light: "1C1C1E", dark: "F5F5F7")

    static var onAccent: UIColor { .canvas }

    private static func adaptive(light: String, dark: String) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}
