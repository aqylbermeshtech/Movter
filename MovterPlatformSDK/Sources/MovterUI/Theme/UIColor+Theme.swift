//
//  UIColor+Theme.swift
//  MovterUI
//
//  Created by Nurtore on 22.03.2026.
//

import SwiftUI
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

    // MARK: - Ticket stub
    static let ticketBackground  = adaptive(light: "1F1F1F", dark: "F2EDE0")
    static let ticketPanel       = adaptive(light: "2E2E2E", dark: "DED6C4")
    static let ticketHeader      = adaptive(light: "E0B54A", dark: "1C1C1C")
    static let ticketPrimaryText = adaptive(light: "FFFFFF", dark: "1C1C1C")
    static let ticketMutedText   = adaptive(light: "9E9E9E", dark: "5C5954")
    static let ticketScore       = adaptive(light: "E0B54A", dark: "AD2924")
    static let ticketDivider     = adaptive(light: "E0B54A", lightAlpha: 0.60, dark: "000000", darkAlpha: 0.28)
    static let ticketPerforation = adaptive(light: "FFFFFF", lightAlpha: 0.22, dark: "000000", darkAlpha: 0.26)
    static let ticketPosterBorder = adaptive(light: "EBEBEB", lightAlpha: 0.85, dark: "000000", darkAlpha: 0.18)
    static let ticketTapeFill    = adaptive(light: "EDDEC7", lightAlpha: 0.78, dark: "D6BF8F", darkAlpha: 0.84)
    static let ticketTapeStroke  = adaptive(light: "FFFFFF", lightAlpha: 0.28, dark: "000000", darkAlpha: 0.14)

    private static func adaptive(
        light: String,
        lightAlpha: CGFloat = 1.0,
        dark: String,
        darkAlpha: CGFloat = 1.0
    ) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark).withAlphaComponent(darkAlpha)
                : UIColor(hex: light).withAlphaComponent(lightAlpha)
        }
    }
}

public extension Color {
    static let ticketBackground   = Color(uiColor: .ticketBackground)
    static let ticketPanel        = Color(uiColor: .ticketPanel)
    static let ticketHeader       = Color(uiColor: .ticketHeader)
    static let ticketPrimaryText  = Color(uiColor: .ticketPrimaryText)
    static let ticketMutedText    = Color(uiColor: .ticketMutedText)
    static let ticketScore        = Color(uiColor: .ticketScore)
    static let ticketDivider      = Color(uiColor: .ticketDivider)
    static let ticketPerforation  = Color(uiColor: .ticketPerforation)
    static let ticketPosterBorder = Color(uiColor: .ticketPosterBorder)
    static let ticketTapeFill     = Color(uiColor: .ticketTapeFill)
    static let ticketTapeStroke   = Color(uiColor: .ticketTapeStroke)
}
