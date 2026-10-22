//
//  ProfileViewModel.swift
//  Movter
//
//  Created by Nurtore on 01.07.2026.
//

import UIKit

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
    var detail: String?
}

struct ProfileSection {
    let header: String?
    let options: [ProfileOption]
}

@MainActor
final class ProfileViewModel {

    static let privacyPolicyURL = URL(string: "https://www.themoviedb.org/privacy-policy")!

    // MARK: - Dependencies

    private let getProfileUseCase: GetProfileUseCase
    private let getProfileStatsUseCase: GetProfileStatsUseCase
    private let signOutUseCase: SignOutUseCase
    private let changeThemeUseCase: ChangeThemeUseCase

    // MARK: - State

    private(set) var state: ProfileViewState = .loading {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((ProfileViewState) -> Void)?
    var onNavigationRequired: ((ProfileOptionType) -> Void)?

    private(set) var sections: [ProfileSection] = []

    // MARK: - Initialization

    init(
        getProfileUseCase: GetProfileUseCase,
        getProfileStatsUseCase: GetProfileStatsUseCase,
        signOutUseCase: SignOutUseCase,
        changeThemeUseCase: ChangeThemeUseCase
    ) {
        self.getProfileUseCase = getProfileUseCase
        self.getProfileStatsUseCase = getProfileStatsUseCase
        self.signOutUseCase = signOutUseCase
        self.changeThemeUseCase = changeThemeUseCase
        rebuildSections()
    }

    // MARK: - Actions

    func loadProfile() async {
        state = .loading
        do {
            async let userTask = getProfileUseCase.execute()
            async let statsTask = getProfileStatsUseCase.execute()

            let (user, stats) = try await (userTask, statsTask)
            let fullUser = UserProfile(
                id: user.id,
                name: user.name,
                email: user.email,
                avatarURL: user.avatarURL,
                memberSinceDate: user.memberSinceDate,
                stats: stats
            )

            rebuildSections(with: stats)
            state = .loaded(fullUser)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reloadStatsOnly() async {
        guard case .loaded(let currentUser) = state else { return }
        do {
            let stats = try await getProfileStatsUseCase.execute()
            let updatedUser = UserProfile(
                id: currentUser.id,
                name: currentUser.name,
                email: currentUser.email,
                avatarURL: currentUser.avatarURL,
                memberSinceDate: currentUser.memberSinceDate,
                stats: stats
            )
            rebuildSections(with: stats)
            state = .loaded(updatedUser)
        } catch {
            // Keep existing state if background stats refresh encounters an error
        }
    }

    func rebuildSections(with stats: ProfileStats? = nil) {
        let watchlistCount = stats?.watchlistCount ?? 0
        sections = [
            ProfileSection(header: "ACCOUNT", options: [
                ProfileOption(title: "Recent Reviews", iconName: "star.bubble", type: .reviews),
                ProfileOption(
                    title: "My Watchlist",
                    iconName: "bookmark",
                    type: .watchlist,
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
        changeThemeUseCase.execute(theme: theme)
        if case .loaded(let user) = state {
            rebuildSections(with: user.stats)
        } else {
            rebuildSections()
        }
    }

    func signOut() async throws {
        try await signOutUseCase.execute()
    }
}
