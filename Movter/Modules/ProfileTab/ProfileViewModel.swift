//
//  ProfileViewModel.swift
//  Movter
//
//  Created by Nurtore on 01.07.2026.
//

import UIKit
import FirebaseAuth

enum ProfileOptionType {
    case reviews
    case watchlist
    case editProfile
    case notifications
    case privacyPolicy
    case changeTheme
    case logout
}

struct ProfileOption {
    let title: String
    let iconName: String
    let type: ProfileOptionType
    /// Right-hand detail text, e.g. the theme currently selected.
    var detail: String?
}

struct ProfileSection {
    let header: String?
    let options: [ProfileOption]
}

final class ProfileViewModel {

    /// Points at the data provider's until the app publishes its own.
    static let privacyPolicyURL = URL(string: "https://www.themoviedb.org/privacy-policy")!

    var onNavigationRequired: ((ProfileOptionType) -> Void)?
    /// Each count lands separately, so the header redraws as they arrive.
    var onStatsChange: (() -> Void)?

    private let watchlistStore: WatchlistStoring
    private let watchedStore: WatchlistStoring
    private let reviewStore: ReviewStoring

    init(
        watchlistStore: WatchlistStoring,
        watchedStore: WatchlistStoring,
        reviewStore: ReviewStoring
    ) {
        self.watchlistStore = watchlistStore
        self.watchedStore = watchedStore
        self.reviewStore = reviewStore
        rebuildSections()
    }

    private var user: User? { Auth.auth().currentUser }

    // MARK: - Stats

    private(set) var watchedCount = 0
    private(set) var reviewsCount = 0
    private(set) var watchlistCount = 0

    /// Three independent stores, so three independent requests — each one publishes as
    /// it lands rather than the header waiting on the slowest.
    func loadStats() {
        watchedStore.fetchAll { [weak self] result in
            if case let .success(items) = result { self?.watchedCount = items.count }
            self?.publishStats()
        }
        reviewStore.fetchAll { [weak self] result in
            if case let .success(reviews) = result { self?.reviewsCount = reviews.count }
            self?.publishStats()
        }
        watchlistStore.fetchAll { [weak self] result in
            if case let .success(items) = result { self?.watchlistCount = items.count }
            self?.publishStats()
        }
    }

    private func publishStats() {
        // The watchlist row carries its count, so the rows move with the numbers.
        rebuildSections()
        onStatsChange?()
    }

    // MARK: - Header

    var userName: String {
        let displayName = user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let displayName = displayName, !displayName.isEmpty { return displayName }
        // Something recognisable, rather than a generic "User".
        if let emailName = user?.email?.split(separator: "@").first { return String(emailName) }
        return "Your Profile"
    }

    var avatarImage: UIImage {
        InitialsAvatar.image(name: user?.displayName, email: user?.email, size: 200)
    }

    /// "Member since August 2026", from real account metadata.
    var memberSinceText: String? {
        guard let created = user?.metadata.creationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return "Member since \(formatter.string(from: created))"
    }

    // MARK: - Sections

    private(set) var sections: [ProfileSection] = []

    func rebuildSections() {
        sections = [
            ProfileSection(header: "ACCOUNT", options: [
                ProfileOption(title: "Recent Reviews", iconName: "star.bubble", type: .reviews),
                ProfileOption(
                    title: "My Watchlist",
                    iconName: "bookmark",
                    type: .watchlist,
                    // Nothing rather than a "0" for an empty watchlist.
                    detail: watchlistCount > 0 ? "\(watchlistCount)" : nil
                ),
                ProfileOption(title: "Edit Profile", iconName: "person.crop.circle", type: .editProfile)
            ]),
            ProfileSection(header: "PREFERENCES", options: [
                ProfileOption(title: "Notifications", iconName: "bell", type: .notifications),
                ProfileOption(
                    title: "App Theme",
                    iconName: "paintbrush",
                    type: .changeTheme,
                    detail: ThemeManager.shared.currentTheme.displayName
                )
            ]),
            ProfileSection(header: "ABOUT", options: [
                ProfileOption(title: "Privacy Policy", iconName: "lock.shield", type: .privacyPolicy)
            ]),
            ProfileSection(header: nil, options: [
                ProfileOption(title: "Log Out", iconName: "rectangle.portrait.and.arrow.right", type: .logout)
            ])
        ]
    }

    func option(at indexPath: IndexPath) -> ProfileOption? {
        guard let section = sections[safe: indexPath.section] else { return nil }
        return section.options[safe: indexPath.row]
    }

    func didSelectOption(at indexPath: IndexPath) {
        guard let option = option(at: indexPath) else { return }
        onNavigationRequired?(option.type)
    }

    func changeTheme(to theme: AppTheme) {
        ThemeManager.shared.selectTheme(theme)
        rebuildSections()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
