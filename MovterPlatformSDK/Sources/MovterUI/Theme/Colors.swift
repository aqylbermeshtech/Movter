//
//  Colors.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import SwiftUI
import UIKit

public extension Color {
    // MARK: - Primary Colors
    static let primary = Color(hex: "#083A6B")
    static let brandPrimary = Color(hex: "#083A6B")
    static let secondprimary = Color(hex: "#083A6B").opacity(0.6)
    static let secondary = Color(hex: "#FF9500")

    // MARK: - Background Colors
    static let background = Color(hex: "#FFFFFF")
    static let backgroundCode = Color(hex: "#F3F5F7")
    static let surface = Color(hex: "#F3F5F7")
    static let surfaceVariant = Color(hex: "#FAFAFA")
    static let iceblue = Color(hex: "#D9E3F2")
    static let redbutton = Color(hex: "#F7D9D7")
    static let line = Color(hex: "#D2D4D7")

    // MARK: - Text Colors
    static let textPrimary = Color(hex: "#010101")
    static let textSecondary = Color(hex: "#3C3C43").opacity(0.6)
    static let textPlaceholderActive = Color(hex: "#1C1C1E")
    static let textPlaceholderInactive = Color(hex: "#3C3C43").opacity(0.18)
    static let textPlaceholder = Color(hex: "#3C3C43").opacity(0.18)
    static let textDisabled = Color(hex: "#3C3C43").opacity(0.18)
    static let onPrimary = Color.white
    static let onSurface = Color(hex: "#010101")
    static let onBackground = Color(hex: "#010101")
    static let codeColor = Color(hex: "#000000")
    static let timerColor = Color(hex: "#FFFFFF").opacity(0.5)
    static let textInactive = Color(hex: "#C4C4C7")

    // MARK: - Input Colors
    static let inputBackground = Color(hex: "#F3F5F7")
    static let inputBorder = Color.clear
    static let inputBackgroundActive = Color(hex: "#F3F5F7")

    // MARK: - Button Colors
    static let buttonPrimary = Color(hex: "#083A6B")
    static let buttonDisabled = Color(hex: "#3C3C43").opacity(0.18)
    static let buttonDisabled2 = Color(hex: "#083A6B").opacity(0.5)
    static let buttonSecondary = Color(hex: "#F3F5F7")
    static let buttonTextDisabled = Color.white.opacity(0.6)

    // MARK: - Semantic Colors
    static let success = Color(hex: "#4CAF50")
    static let error = Color(hex: "#F44336")
    static let warning = Color(hex: "#FF9800")
    static let info = Color(hex: "#2196F3")

    // MARK: - Divider Colors
    static let divider = Color(hex: "#E0E0E0")
    static let dividerList = Color(hex: "#C6C6C8")
    static let separatorVibrant = Color(hex: "#E6E6E6")

    // MARK: - Grabber Colors
    static let grabber = Color(hex: "#3C3C43").opacity(0.18)

    // MARK: - Segment Control Colors
    static let segmentBackground = Color(hex: "#F3F5F7")
    static let segmentActive = Color(hex: "#FFFFFF")
    static let segmentTextActive = Color(hex: "#010101")
    static let segmentTextInactive = Color(hex: "#3C3C43").opacity(0.6)

    // MARK: - Selection Colors
    static let selectionBackground = Color(hex: "#175BED").opacity(0.1)
    static let selectedSlotBackground = Color(hex: "#E8EFFD")

    // MARK: - Search Bar Colors
    static let searchBackground = Color(hex: "#787880").opacity(0.16)
    static let searchText = Color(hex: "#010101")
    static let searchIcon = Color(hex: "#999999")
    static let searchPlaceholder = Color(hex: "#999999")

    // MARK: - Shadow Colors
    static let shadow = Color.black.opacity(0.08)

    // MARK: - TabBar Colors
    static let tabBarBackground = Color.white
    static let tabBarActive = Color.primary
    static let tabBarInactive = Color(hex: "#3C3C43").opacity(0.6)
    static let tabBarDivider = Color(hex: "#3C3C43").opacity(0.1)
    static let tabBarIndicator = Color.primary

    // MARK: - Quick Action Gradient Colors
    static let quickActionCareerPlanGradientStart = Color(hex: "#EB6F0A")
    static let quickActionCareerPlanGradientEnd = Color(hex: "#F48B38")

    static let quickActionInterviewPrepGradientStart = Color(hex: "#8237FF").opacity(0.5)
    static let quickActionInterviewPrepGradientEnd = Color(hex: "#9B60FE")

    static let quickActionCodeReviewGradientStart = Color(hex: "#FA7761")
    static let quickActionCodeReviewGradientEnd = Color(hex: "#FF3D22")

    // MARK: - Tag Colors
    static let tagBackground = Color(hex: "#F3F4F6")
    static let ratingStarColor = Color(hex: "#FBC36D")
    static let highlightBadgeBackground = Color(hex: "#083A6B").opacity(0.08)
    static let highlightBadgeText = Color(hex: "#083A6B")
    static let profileGradientStart = Color(hex: "#083A6B")
    static let profileGradientEnd = Color(hex: "#3B79B8")

    // MARK: - Status Colors
    static let statusAvailableToday = Color(hex: "#7AB66D")
    static let statusAvailableTomorrow = Color(hex: "#EB704A")
    static let statusCancelledBackground = Color(hex: "#8A8A8E")

    // MARK: - Personalities Colors
    static let personalitiesHeroGradientStart = Color(hex: "#090D1F").opacity(0.98)
    static let personalitiesHeroGradientMiddle = Color(hex: "#11183A").opacity(0.76)
    static let personalitiesHeroGradientEnd = Color.clear
    static let personalitiesHeroText = Color.white
    static let personalitiesHeroSecondaryText = Color.white.opacity(0.92)
    static let personalitiesHeroButtonBackground = Color.white
    static let personalitiesHeroButtonText = Color(hex: "#12172A")
    static let personalitiesHeroChevronIcon = Color.white
    static let personalitiesHeroChevronBackground = Color.black.opacity(0.28)
    static let personalitiesCardBackground = Color.white
    static let personalitiesCardTitle = Color(hex: "#141827")
    static let personalitiesCardText = Color(hex: "#596070")
    static let personalitiesQuestionText = Color(hex: "#4B5263")
    static let personalitiesPremiumIcon = Color(hex: "#D3A02B")
    static let personalitiesPremiumButton = Color(hex: "#C9972B")
    static let personalitiesPremiumButtonText = Color.white
    static let personalitiesPremiumBackground = Color(hex: "#FFFDF7")
    static let personalitiesPremiumBorder = Color(hex: "#EBD8A6")
    static let personalitiesIconBackground = Color(hex: "#F4F6FB")
    static let personalitiesDialogCountBackground = Color(hex: "#F7F7FD")
    static let personalitiesOutcomeBorder = Color(hex: "#ECEFF3")
    static let personalitiesHeroShadow = Color.black.opacity(0.16)
    static let personalitiesCardShadow = Color.black.opacity(0.06)
    static let personalitiesQuestionShadow = Color(hex: "#2D285F").opacity(0.08)
}

// MARK: - Helper Extensions

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

