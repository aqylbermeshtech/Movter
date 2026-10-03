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

// MARK: - UIFont Semantic Tokens
//
// Named for the job rather than the point size, the same way the colour ramp is.
// Every token — and every one-off below — routes through `movter(size:weight:)`, so
// putting a custom face in front of the whole app is a change to one function
// rather than to a hundred call sites.
//
// Several names share a size and weight. That is deliberate: a stat number and an
// empty-state title are the same size today and may not stay that way, and a call
// site that says what it is stays readable either way.

public extension UIFont {

    // MARK: Display

    /// Screen titles: the home wordmark, sign-in, the hero film title.
    static let screenTitle         = movter(size: 28, weight: .bold)
    /// A title carried on a card rather than a page — the ticket stub, a swipe card.
    static let cardTitle           = movter(size: 24, weight: .bold)

    /// In-page section headings. `Strong` is the home and search variant; the two
    /// should probably converge, and this is where that decision would be made.
    static let sectionHeader       = movter(size: 22, weight: .semibold)
    static let sectionHeaderStrong = movter(size: 22, weight: .bold)
    /// The headline of an empty or unavailable screen.
    static let emptyStateTitle     = movter(size: 22, weight: .bold)
    /// The numbers on the profile's stat tiles.
    static let statValue           = movter(size: 22, weight: .bold)
    /// The signed-in person's own name.
    static let profileName         = movter(size: 22, weight: .bold)

    /// The headline inside a placeholder card — no cast, no trailer, offline.
    static let placeholderTitle    = movter(size: 19, weight: .semibold)
    /// A group heading inside a list, sitting below the screen's own title.
    static let groupHeader         = movter(size: 19, weight: .semibold)

    // MARK: Body

    /// Synopses, biographies, anything read a paragraph at a time.
    static let body                = movter(size: 16, weight: .regular)
    /// The first line of a list row.
    static let rowTitle            = movter(size: 16, weight: .semibold)
    /// A full-width button that carries a screen.
    static let primaryButton       = movter(size: 16, weight: .semibold)
    /// Heavier still, for the one action a screen exists to perform.
    static let prominentButton     = movter(size: 16, weight: .bold)

    // MARK: Secondary

    /// Supporting copy: subtitles, placeholder bodies, help text.
    static let secondaryBody       = movter(size: 15, weight: .regular)
    /// The app's standard button text — Save Review, Mark as watched, See ticket.
    static let button              = movter(size: 15, weight: .semibold)
    /// A label pulled forward from the copy around it without being a heading.
    static let emphasized          = movter(size: 15, weight: .semibold)
    /// The rating · year · genre line, and anything else stated about a title.
    static let metadata            = movter(size: 15, weight: .medium)

    // MARK: Captions

    /// The second line of a row: a character name, a job, a date.
    static let caption             = movter(size: 14, weight: .regular)
    /// A caption with weight behind it — a score beside a review.
    static let emphasisCaption     = movter(size: 14, weight: .semibold)
    /// Genre chips and filter pills.
    static let chip                = movter(size: 14, weight: .semibold)
    /// "See all" and the other quiet ways further into a section.
    static let linkButton          = movter(size: 14, weight: .semibold)
    /// The caption under a poster or a headshot in a carousel.
    static let cellTitle           = movter(size: 14, weight: .bold)
    /// The capsule actions on the details header.
    static let capsuleButton       = movter(size: 14, weight: .bold)

    /// Fine print that still has to be read: hints, timestamps, counts.
    static let footnote            = movter(size: 13, weight: .regular)
    /// A button sized down to caption weight.
    static let captionButton       = movter(size: 13, weight: .semibold)
    /// The grouped-table section headers UIKit would otherwise style itself.
    static let tableSectionHeader  = movter(size: 13, weight: .semibold)

    /// The smallest copy that is still a sentence.
    static let fineprint           = movter(size: 12, weight: .regular)
    /// The score chip over artwork, and the release date standing in for one.
    static let badge               = movter(size: 12, weight: .semibold)
    /// The label above a form field.
    static let fieldLabel          = movter(size: 12, weight: .semibold)

    /// Type at the edge of legibility, used only where the shape carries the meaning.
    static let microLabel          = movter(size: 11, weight: .semibold)
    /// The "FEATURED" flag on the hero card.
    static let eyebrow             = movter(size: 11, weight: .heavy)
    /// The tab bar's own labels.
    static let tabLabel            = movter(size: 10, weight: .medium)

    // MARK: - The one place the face is chosen

    /// Every font in the app comes from here, including the sizes too one-off to earn a
    /// name. Swapping in a bundled face is a change to this body — and, if it is ever
    /// scaled for Dynamic Type, that belongs here too rather than at each call site.
    static func movter(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        .systemFont(ofSize: size, weight: weight)
    }
}

