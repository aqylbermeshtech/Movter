//
//  MainTabBarFactory.swift
//  Movter
//

import UIKit
import FirebaseAuth

@MainActor
enum MainTabBarFactory {

    static func makeTabBar() -> UIViewController {
        let watchlistStore = WatchlistStoreFactory.makeStore()
        let seenFilmsStore = SeenFilmsStoreFactory.makeStore()
        let reviewStore = ReviewStoreFactory.makeStore()
        let watchedStore = WatchedFilmsStoreFactory.makeStore()

        let mediaListVC = MediaListViewController(watchlistStore: watchlistStore)
        let searchMoviesVC = SearchMoviesViewController()
        let swipeDeckVC = SwipeDeckViewController(watchlistStore: watchlistStore, seenFilmsStore: seenFilmsStore)
        let profileVC = ProfileViewController(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )

        let roots: [TabActionProviding] = [mediaListVC, searchMoviesVC, swipeDeckVC, profileVC]
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
