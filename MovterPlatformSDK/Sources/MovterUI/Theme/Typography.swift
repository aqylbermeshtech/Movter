//
//  Typography.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import SwiftUI
import UIKit

// MARK: - Typography (Semantic Styles)
public struct Typography {
   
    // MARK: - Authentication Screen Styles
    public static let authTitle = Font.system(size: 28, weight: .semibold, design: .default)
    public static let segmentActive = Font.system(size: 14, weight: .medium, design: .default)
    public static let segmentInactive = Font.system(size: 14, weight: .regular, design: .default)
    public static let inputText = Font.system(size: 17, weight: .regular, design: .default)
    public static let buttonPrimary = Font.system(size: 16, weight: .medium, design: .default)
    public static let policyText = Font.system(size: 13, weight: .regular, design: .default)
    public static let policyLink = Font.system(size: 13, weight: .semibold, design: .default)
    public static let dividerText = Font.system(size: 13, weight: .regular, design: .default)
    public static let cancelButton = Font.system(size: 15, weight: .regular, design: .default)
    public static let sectionHeader = Font.system(size: 17, weight: .semibold, design: .default)
    public static let codeText = Font.system(size: 32, weight: .medium, design: .default)
    public static let anotherWay = Font.system(size: 16, weight: .regular, design: .default)
    public static let errorText = Font.system(size: 17, weight: .semibold, design: .default)
    public static let resendButtonTitle = Font.system(size: 17, weight: .medium, design: .default)
    public static let resendButtonSubtitle = Font.system(size: 13, weight: .regular, design: .default)
    public static let otpSubtitle = Font.system(size: 15, weight: .regular, design: .default)
    public static let aboutMentor: Font = .system(size: 22, weight: .semibold)
    public static let descriptionText = Font.system(size: 15, weight: .regular, design: .default)
    public static let reviewText = Font.system(size: 15, weight: .regular, design: .default).italic()

    // MARK: - Profile Setup Styles
    public static let setupRowText = Font.system(size: 15, weight: .regular, design: .default)
    public static let addLaterButton = Font.system(size: 16, weight: .regular, design: .default)

    // MARK: - Role Selection Styles
    public static let roleCardTitle = Font.system(size: 24, weight: .semibold, design: .default)
    public static let roleCardSubtitle = Font.system(size: 14, weight: .regular, design: .default)
    public static let navigationTitle = Font.system(size: 17, weight: .semibold, design: .default)

    // MARK: - TabBar Styles
    public static let tabBarLabel = Font.system(size: 10, weight: .medium, design: .default)

    // MARK: - QuickAction Card Styles
    public static let quickActionTitle = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Main Navigation Bar Styles
    public static let navigationBarTitle = Font.system(size: 17, weight: .medium, design: .default)
    public static let navigationBarSubtitle = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Tag Styles
    public static let tagRating = Font.system(size: 11, weight: .regular, design: .default)
    public static let tagSkill = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Section Header Styles

    public static let sectionTitle = Font.system(size: 19, weight: .semibold, design: .default)
    public static let sectionViewAll = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Display Styles (для других экранов)
    public static let displayLarge = Font.system(size: 57, weight: .regular)
    public static let displayMedium = Font.system(size: 45, weight: .regular)
    public static let displaySmall = Font.system(size: 36, weight: .regular)

    // MARK: - Headline Styles
    public static let headlineLarge = Font.system(size: 32, weight: .bold)
    public static let headlineMedium = Font.system(size: 28, weight: .semibold)
    public static let headlineSmall = Font.system(size: 24, weight: .regular)

    // MARK: - Title Styles
    public static let titleLarge = Font.system(size: 22, weight: .regular)
    public static let titleMedium = Font.system(size: 16, weight: .medium)
    public static let titleSmall = Font.system(size: 14, weight: .medium)

    // MARK: - Label Styles
    public static let labelLarge = Font.system(size: 14, weight: .medium)
    public static let labelMedium = Font.system(size: 12, weight: .medium)
    public static let labelSmall = Font.system(size: 11, weight: .medium)

    // MARK: - Body Styles
    public static let bodyLarge = Font.system(size: 17, weight: .regular)
    public static let bodyMedium = Font.system(size: 14, weight: .regular)
    public static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Button Styles
    public static let buttonLarge = Font.system(size: 16, weight: .semibold)
    public static let buttonMedium = Font.system(size: 14, weight: .semibold)
    public static let buttonSmall = Font.system(size: 12, weight: .semibold)

    // MARK: - Caption Styles
    public static let caption = Font.system(size: 13, weight: .regular)
    public static let overline = Font.system(size: 10, weight: .regular)

    // MARK: - Regular
    public static let regular16: Font = .system(size: 16, weight: .regular)
    public static let regular14: Font = .system(size: 14, weight: .regular)
    public static let regular13 = Font.system(size: 13, weight: .regular)
    public static let regular12: Font = .system(size: 12, weight: .regular)
    public static let regular10: Font = .system(size: 10, weight: .regular)
    public static let regular15: Font = .system(size: 15, weight: .regular)
    public static let regular11: Font = .system(size: 11, weight: .regular)

    // MARK: - Semibold
    public static let semibold22: Font = .system(size: 22, weight: .semibold)
    public static let semibold16: Font = .system(size: 16, weight: .semibold)
    public static let semibold17: Font = .system(size: 17, weight: .semibold)
    public static let semibold15: Font = .system(size: 15, weight: .semibold)
    public static let semibold14: Font = .system(size: 14, weight: .semibold)
    
    // MARK: - Bold
    public static let bold24: Font = .system(size: 24, weight: .bold)
    public static let bold18: Font = .system(size: 18, weight: .bold)
    public static let bold16: Font = .system(size: 16, weight: .bold)
    public static let bold14: Font = .system(size: 14, weight: .bold)
    public static let bold12: Font = .system(size: 12, weight: .bold)
    public static let bold10: Font = .system(size: 10, weight: .bold)

    // MARK: - Medium
    public static let medium44: Font = .system(size: 44, weight: .medium)
    public static let uiMedium44: UIFont = .systemFont(ofSize: 44, weight: .medium)
    public static let medium40: Font = .system(size: 40, weight: .medium)
    public static let medium24: Font = .system(size: 24, weight: .medium)
    public static let medium20: Font = .system(size: 20, weight: .medium)
    public static let medium18: Font = .system(size: 18, weight: .medium)
    public static let medium17: Font = .system(size: 17, weight: .medium)
    public static let medium16: Font = .system(size: 16, weight: .medium)
    public static let medium15: Font = .system(size: 15, weight: .medium)
    public static let medium14: Font = .system(size: 14, weight: .medium)
    public static let medium12: Font = .system(size: 12, weight: .medium)
    public static let medium13: Font = .system(size: 13, weight: .medium)
    public static let medium10: Font = .system(size: 10, weight: .medium)
    public static let medium8: Font = .system(size: 8, weight: .medium)

    // MARK: - Emoji Fonts
    public static let emojiSmall: Font = .system(size: 16)
    public static let emojiMedium: Font = .system(size: 20)
    public static let emojiRow: Font = .system(size: 22)
    public static let emojiLarge: Font = .system(size: 24)
}

// MARK: - Font Extensions
public extension Font {
    static func mentor(_ style: MentorFontStyle) -> Font {
        switch style {
        case .authTitle: return Typography.authTitle
        case .segmentActive: return Typography.segmentActive
        case .segmentInactive: return Typography.segmentInactive
        case .inputText: return Typography.inputText
        case .buttonPrimary: return Typography.buttonPrimary
        case .policyText: return Typography.policyText
        case .policyLink: return Typography.policyLink
        case .dividerText: return Typography.dividerText
        case .displayLarge: return Typography.displayLarge
        case .displayMedium: return Typography.displayMedium
        case .displaySmall: return Typography.displaySmall
        case .headlineLarge: return Typography.headlineLarge
        case .headlineMedium: return Typography.headlineMedium
        case .headlineSmall: return Typography.headlineSmall
        case .titleLarge: return Typography.titleLarge
        case .titleMedium: return Typography.titleMedium
        case .titleSmall: return Typography.titleSmall
        case .labelLarge: return Typography.labelLarge
        case .labelMedium: return Typography.labelMedium
        case .labelSmall: return Typography.labelSmall
        case .bodyLarge: return Typography.bodyLarge
        case .bodyMedium: return Typography.bodyMedium
        case .bodySmall: return Typography.bodySmall
        case .buttonLarge: return Typography.buttonLarge
        case .buttonMedium: return Typography.buttonMedium
        case .buttonSmall: return Typography.buttonSmall
        case .caption: return Typography.caption
        case .overline: return Typography.overline
        }
    }
}

public enum MentorFontStyle: CaseIterable {
    case authTitle
    case segmentActive, segmentInactive
    case inputText
    case buttonPrimary
    case policyText, policyLink
    case dividerText
    case displayLarge, displayMedium, displaySmall
    case headlineLarge, headlineMedium, headlineSmall
    case titleLarge, titleMedium, titleSmall
    case labelLarge, labelMedium, labelSmall
    case bodyLarge, bodyMedium, bodySmall
    case buttonLarge, buttonMedium, buttonSmall
    case caption, overline
}

