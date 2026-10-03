//
//  Spacing.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import SwiftUI

public struct Spacing {
    // MARK: - Basic Spacing Scale
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let ms: CGFloat = 12
    public static let md: CGFloat = 16
    public static let ml: CGFloat = 20
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let xxx: CGFloat = 50
    public static let xxxl: CGFloat = 64
    public static let xxxll: CGFloat = 65
    public static let xxxxl: CGFloat = 103

    // MARK: - Component Specific Spacing
    public static let padding = md
    public static let margin = md

    // MARK: - Animation Durations
    public static let animationVeryFast: Double = 0.15
    public static let animationFast: Double = 0.2
    public static let animationQuick: Double = 0.25
    public static let animationMedium: Double = 0.3
    public static let animationLong: Double = 0.4
    public static let animationSlow: Double = 0.5
    public static let animationDuration: Double = 0.45

    // MARK: - Corner Radius

    public static let cornerRadiusNone: CGFloat = 0
    public static let cornerRadiusXxs: CGFloat = 2
    public static let cornerRadiusXs: CGFloat = 4
    public static let cornerRadiusSm: CGFloat = 6
    public static let cornerRadiusMd: CGFloat = 8
    public static let cornerRadiusLg: CGFloat = 12
    public static let cornerRadiusMs: CGFloat = 10
    public static let cornerRadiusXl: CGFloat = 15
    public static let cornerRadiusXxm: CGFloat = 20
    public static let cornerRadiusXxl: CGFloat = 24

    public static let cornerRadius: CGFloat = cornerRadiusMd
    public static let cornerRadiusLarge: CGFloat = cornerRadiusLg
    public static let cornerRadiusSmall: CGFloat = cornerRadiusXs
}

// MARK: - EdgeInsets Extensions
public extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    static let small = EdgeInsets(top: Spacing.sm, leading: Spacing.sm, bottom: Spacing.sm, trailing: Spacing.sm)
    static let medium = EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
    static let large = EdgeInsets(top: Spacing.lg, leading: Spacing.lg, bottom: Spacing.lg, trailing: Spacing.lg)

    static func horizontal(_ value: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value)
    }

    static func vertical(_ value: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0)
    }

    static func all(_ value: CGFloat) -> EdgeInsets {
        return EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }
}

// MARK: - CornerRadius Extensions
public extension CGFloat {

    var cornerRadius: CGFloat {
        return self
    }
}

// MARK: - Legacy CornerRadius Compatibility
public struct CornerRadius {
    // MARK: - Basic Corner Radius Scale
    public static let none: CGFloat = Spacing.cornerRadiusNone
    public static let xxs: CGFloat = Spacing.cornerRadiusXxs
    public static let xs: CGFloat = Spacing.cornerRadiusXs
    public static let sm: CGFloat = Spacing.cornerRadiusSm
    public static let ms: CGFloat = Spacing.cornerRadiusMs
    public static let md: CGFloat = Spacing.cornerRadiusMd
    public static let lg: CGFloat = Spacing.cornerRadiusLg
    public static let xl: CGFloat = Spacing.cornerRadiusXl
    public static let xxl: CGFloat = Spacing.cornerRadiusXxl
    public static let xxm: CGFloat = Spacing.cornerRadiusXxm

    // MARK: - Component Specific
    public static let button: CGFloat = Spacing.cornerRadiusMs // 10

    // MARK: - Legacy
    public static let cornerRadius: CGFloat = Spacing.cornerRadius
    public static let cornerRadiusLarge: CGFloat = Spacing.cornerRadiusLarge
    public static let cornerRadiusSmall: CGFloat = Spacing.cornerRadiusSmall
}

