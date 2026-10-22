//
//  ProfileCoordinator.swift
//  Movter
//

import UIKit
import SafariServices

@MainActor
protocol ProfileCoordinator: AnyObject {
    func showReviews()
    func showWatched()
    func showWatchlist()
    func showEditProfile(onSave: @escaping () -> Void)
    func showNotifications()
    func showPrivacyPolicy(url: URL)
    func showLogin()
}

@MainActor
final class DefaultProfileCoordinator: ProfileCoordinator {

    weak var viewController: UIViewController?
    weak var navigationController: UINavigationController?

    private let watchlistStore: WatchlistStoring
    private let watchedStore: WatchlistStoring
    private let reviewStore: ReviewStoring

    private var activeNavigationController: UINavigationController? {
        navigationController ?? viewController?.navigationController
    }

    init(
        navigationController: UINavigationController? = nil,
        watchlistStore: WatchlistStoring,
        watchedStore: WatchlistStoring,
        reviewStore: ReviewStoring
    ) {
        self.navigationController = navigationController
        self.watchlistStore = watchlistStore
        self.watchedStore = watchedStore
        self.reviewStore = reviewStore
    }

    func showReviews() {
        let reviewsVC = ReviewsListViewController(
            viewModel: ReviewsListViewModel(store: reviewStore)
        )
        activeNavigationController?.pushViewController(reviewsVC, animated: true)
    }

    func showWatched() {
        let watchedVC = WatchlistListViewController(
            viewModel: WatchlistListViewModel(store: watchedStore, presentation: .watched)
        )
        activeNavigationController?.pushViewController(watchedVC, animated: true)
    }

    func showWatchlist() {
        let watchlistVC = WatchlistListViewController(
            viewModel: WatchlistListViewModel(store: watchlistStore)
        )
        activeNavigationController?.pushViewController(watchlistVC, animated: true)
    }

    func showEditProfile(onSave: @escaping () -> Void) {
        let editVC = EditProfileViewController()
        editVC.onSave = onSave
        activeNavigationController?.pushViewController(editVC, animated: true)
    }

    func showNotifications() {
        let notificationsVC = NotificationSettingsViewController()
        activeNavigationController?.pushViewController(notificationsVC, animated: true)
    }

    func showPrivacyPolicy(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        let presenter = activeNavigationController ?? viewController
        presenter?.present(safariVC, animated: true)
    }

    func showLogin() {
        guard let window = (activeNavigationController ?? viewController)?.view.window else { return }
        let loginNav = UINavigationController(rootViewController: LoginViewController())
        window.rootViewController = loginNav
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
