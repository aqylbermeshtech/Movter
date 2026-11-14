//
//  MainTabBarFactory.swift
//  Movter
//

import UIKit

@MainActor
enum MainTabBarFactory {

    static func makeTabBar() -> UIViewController {
        let moviesNav = UINavigationController()
        let moviesCoordinator = DefaultMoviesCoordinator(navigationController: moviesNav)
        let mediaListVC = MoviesViewFactory.makeMovieList(coordinator: moviesCoordinator)
        moviesNav.viewControllers = [mediaListVC]

        let searchMoviesVC = SearchMoviesViewController()
        let swipeDeckVC = SwipeViewFactory.makeSwipeDeck()
        let stubsVC = StubsViewController()

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
                    title: "Stubs", symbol: "ticket",
                    navigationController: UINavigationController(rootViewController: stubsVC)
                )
            ],
            searchNavigationController: UINavigationController(rootViewController: searchMoviesVC)
        )
        return tabBar
    }
}
