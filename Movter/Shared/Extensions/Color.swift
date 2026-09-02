//
//  Color.swift
//  Movter
//
//  Created by Nurtore on 22.03.2026.
//

import UIKit

extension UIColor {
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
extension UIColor {

    // MARK: - Neutral ramp
    //
    // Five steps carry the whole interface; posters are the only saturated thing. Every
    // step is dynamic, so one token is a white page in light and a near-black one in
    // dark, and no screen needs to know which it is currently drawing.

    /// App background.
    static let canvas        = adaptive(light: "FFFFFF", dark: "0A0A0B")
    /// Cards, wells and any surface sitting on the canvas.
    static let surface       = adaptive(light: "F2F2F7", dark: "151517")
    /// Hairline borders and separators.
    static let hairline      = adaptive(light: "D7D7DC", dark: "2A2A2E")
    /// Titles and body copy. Held off pure black and pure white, both of which glare
    /// against the canvas at their own end of the ramp.
    static let textPrimary   = adaptive(light: "1C1C1E", dark: "F5F5F7")
    /// Captions, metadata, disabled states.
    static let textSecondary = adaptive(light: "6C6C70", dark: "8A8A8F")

    /// Muted red for destructive actions — the one place colour still means "careful".
    /// Deeper in light, where the dark-mode red washes out against white.
    static let destructive   = adaptive(light: "C0453A", dark: "D96A5A")

    /// The single accent. Monochrome by design and inverted against the page, so posters
    /// stay the only saturated thing on screen in either appearance.
    static let accent        = adaptive(light: "1C1C1E", dark: "F5F5F7")

    /// Drawn on top of `accent`. The accent sits at the far end of the ramp from the
    /// canvas, so the canvas is exactly what reads against it.
    static var onAccent: UIColor { .canvas }

    private static func adaptive(light: String, dark: String) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}
