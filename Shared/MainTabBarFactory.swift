//
//  MainTabBarFactory.swift
//  Movter
//

import UIKit
import FirebaseAuth

enum MainTabBarFactory {
    static func makeTabBar() -> UIViewController {
        // Built per sign-in, so the stores are always scoped to the current account.
        let watchlistStore = WatchlistStoreFactory.makeStore()
        let seenFilmsStore = SeenFilmsStoreFactory.makeStore()

        // No Reviews tab: writing a review is reached through Profile › Reviews, which
        // carries its own add button. Each remaining tab's own primary action lives on
        // the bar's floating action button instead.
        let mediaListVC = MediaListViewController()
        let searchMoviesVC = SearchMoviesController()
        let swipeDeckVC = SwipeDeckViewController(watchlistStore: watchlistStore, seenFilmsStore: seenFilmsStore)
        let profileVC = ProfileViewController()

        let roots: [TabActionProviding] = [mediaListVC, searchMoviesVC, swipeDeckVC, profileVC]
        // Each root reserves its own clearance for the floating bar. Set here on the
        // screen itself rather than on `MainTabBarController` — nested content doesn't
        // reliably honour safe-area insets applied several ancestors up.
        for root in roots {
            root.additionalSafeAreaInsets.bottom = MainTabBarController.contentClearance
        }

        let tabBar = MainTabBarController()
        tabBar.setTabs([
            .init(
                title: "Movies", symbol: "film",
                navigationController: UINavigationController(rootViewController: mediaListVC),
                root: mediaListVC
            ),
            .init(
                title: "Search", symbol: "magnifyingglass",
                navigationController: UINavigationController(rootViewController: searchMoviesVC),
                root: searchMoviesVC
            ),
            .init(
                title: "Swipe", symbol: "flame",
                navigationController: UINavigationController(rootViewController: swipeDeckVC),
                root: swipeDeckVC
            ),
            .init(
                title: "Profile", symbol: "person",
                navigationController: UINavigationController(rootViewController: profileVC),
                root: profileVC
            )
        ])
        return tabBar
    }
}
