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

        let swipeDeckVC = SwipeViewFactory.makeSwipeDeck()

        let stubsNav = UINavigationController()
        let stubsCoordinator = DefaultStubsCoordinator(navigationController: stubsNav)
        let stubsVC = StubsViewFactory.makeStubsDeck(coordinator: stubsCoordinator)
        stubsNav.viewControllers = [stubsVC]

        let libraryNav = UINavigationController()
        let libraryCoordinator = DefaultLibraryCoordinator(navigationController: libraryNav)
        let libraryVC = LibraryViewFactory.makeLibrary(coordinator: libraryCoordinator)
        libraryNav.viewControllers = [libraryVC]

        let tabBar = MainTabBarController()
        tabBar.setTabs(
            [
                .init(
                    title: "Swipe", symbol: "flame",
                    navigationController: UINavigationController(rootViewController: swipeDeckVC)
                ),
                .init(
                    title: "Stubs", symbol: "ticket",
                    navigationController: stubsNav
                ),
                .init(
                    title: "Library", symbol: "books.vertical",
                    navigationController: libraryNav
                )
            ],
            actionTab: .init(
                title: "Home", symbol: "magnifyingglass",
                navigationController: moviesNav
            )
        )
        return tabBar
    }
}
