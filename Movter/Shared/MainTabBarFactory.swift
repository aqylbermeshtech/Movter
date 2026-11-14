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

        let stubsNav = UINavigationController()
        let stubsCoordinator = DefaultStubsCoordinator(navigationController: stubsNav)
        let stubsVC = StubsViewFactory.makeStubsDeck(coordinator: stubsCoordinator)
        stubsNav.viewControllers = [stubsVC]

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
                    navigationController: stubsNav
                )
            ],
            searchNavigationController: UINavigationController(rootViewController: searchMoviesVC)
        )
        return tabBar
    }
}
