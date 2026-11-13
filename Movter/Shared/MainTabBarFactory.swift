//
//  MainTabBarFactory.swift
//  Movter
//

import UIKit

@MainActor
enum MainTabBarFactory {

    static func makeTabBar() -> UIViewController {
        let watchlistStore = WatchlistStoreFactory.makeStore()
        let seenFilmsStore = SeenFilmsStoreFactory.makeStore()
        let reviewStore = ReviewStoreFactory.makeStore()
        let watchedStore = WatchedFilmsStoreFactory.makeStore()

        let moviesNav = UINavigationController()
        let moviesCoordinator = DefaultMoviesCoordinator(navigationController: moviesNav)
        let mediaListVC = MoviesViewFactory.makeMovieList(coordinator: moviesCoordinator)
        moviesNav.viewControllers = [mediaListVC]

        let searchMoviesVC = SearchMoviesViewController()
        let swipeDeckVC = SwipeDeckViewController(watchlistStore: watchlistStore, seenFilmsStore: seenFilmsStore)
        let profileVC = ProfileViewController(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )

        let tabBar = MainTabBarController()
        tabBar.setTabs(
            [
                .init(
                    title: "Movies", symbol: "film",
                    navigationController: moviesNav,
                    root: mediaListVC
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
            ],
            searchNavigationController: UINavigationController(rootViewController: searchMoviesVC)
        )
        return tabBar
    }
}
