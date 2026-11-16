//
//  LibraryCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol LibraryCoordinator: AnyObject {
    func showMovieDetails(for item: LibraryMediaItem)
}

@MainActor
final class DefaultLibraryCoordinator: LibraryCoordinator {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func showMovieDetails(for item: LibraryMediaItem) {
        let moviesCoordinator = DefaultMoviesCoordinator(navigationController: navigationController)
        let detailsVC = MoviesViewFactory.makeMovieDetails(media: item.asMedia, coordinator: moviesCoordinator)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}
