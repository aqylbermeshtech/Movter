//
//  MainTabBarFactory.swift
//  Movter
//

import UIKit

@MainActor
enum MainTabBarFactory {

    static func makeTabBar() -> UIViewController {
        let watchlistStore = WatchlistStoreFactory.makeStore()
        let reviewStore = ReviewStoreFactory.makeStore()
        let watchedStore = WatchedFilmsStoreFactory.makeStore()

        let moviesNav = UINavigationController()
        let moviesCoordinator = DefaultMoviesCoordinator(navigationController: moviesNav)
        let mediaListVC = MoviesViewFactory.makeMovieList(coordinator: moviesCoordinator)
        moviesNav.viewControllers = [mediaListVC]

        let searchMoviesVC = SearchMoviesViewController()
        let swipeDeckVC = SwipeViewFactory.makeSwipeDeck()
        let profileVC = ProfileViewFactory.make(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )

        let tabBar = MainTabBarController()
        tabBar.setTabs(
            [
                .init(
                    title: "Movies", symbol: "film",
                    navigationController: moviesNav
                ),
                .init(
                    title: "Swipe", symbol: "flame",
                    navigationController: UINavigationController(rootViewController: swipeDeckVC)
                ),
                .init(
                    title: "Profile", symbol: "person",
                    navigationController: UINavigationController(rootViewController: profileVC)
                )
            ],
            searchNavigationController: UINavigationController(rootViewController: searchMoviesVC)
        )
        return tabBar
    }
}
