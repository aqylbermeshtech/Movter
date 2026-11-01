//
//  SwipeCoordinator.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
protocol SwipeCoordinator: AnyObject {
    func showWatchlist()
    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource)
    func dismiss()
}

@MainActor
final class DefaultSwipeCoordinator: SwipeCoordinator {

    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?

    private let posterTransition = PosterTransitionController()

    private var activeNavController: UINavigationController? {
        navigationController ?? viewController?.navigationController
    }

    private var activePresenter: UIViewController? {
        navigationController ?? viewController
    }

    init(
        navigationController: UINavigationController? = nil,
        viewController: UIViewController? = nil
    ) {
        self.navigationController = navigationController
        self.viewController = viewController
    }

    func showWatchlist() {
        let watchlistVC = SwipeViewFactory.makeWatchlist(presentation: .watchlist, coordinator: self)
        activeNavController?.pushViewController(watchlistVC, animated: true)
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
        posterTransition.push(detailVC, for: media, from: source)
    }

    func dismiss() {
        activePresenter?.dismiss(animated: true)
    }
}

