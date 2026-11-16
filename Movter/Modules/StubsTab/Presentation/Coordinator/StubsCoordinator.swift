//
//  StubsCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol StubsCoordinator: AnyObject {
    func showAllStubs()
    func showTicketDetails(for review: Review)
    func showPickTopFavorite(onSelect: @escaping (FavoriteFilm) -> Void)
    func showMovieDetails(for film: FavoriteFilm)
}

@MainActor
final class DefaultStubsCoordinator: StubsCoordinator {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func showAllStubs() {
        let listVC = StubsViewFactory.makeStubsList(coordinator: self)
        navigationController?.pushViewController(listVC, animated: true)
    }

    func showTicketDetails(for review: Review) {
        let ticketVC = TicketViewController(review: review)
        let nav = UINavigationController(rootViewController: ticketVC)
        navigationController?.present(nav, animated: true)
    }

    func showPickTopFavorite(onSelect: @escaping (FavoriteFilm) -> Void) {
        var presentedNav: UINavigationController?
        let pickerVC = ReviewsViewFactory.makeFilmPicker { selection in
            presentedNav?.dismiss(animated: true)
            guard case let .catalogue(media) = selection else { return }
            onSelect(FavoriteFilm(media: media))
        }
        let nav = UINavigationController(rootViewController: pickerVC)
        presentedNav = nav
        navigationController?.present(nav, animated: true)
    }

    func showMovieDetails(for film: FavoriteFilm) {
        let moviesCoordinator = DefaultMoviesCoordinator(navigationController: navigationController)
        let detailsVC = MoviesViewFactory.makeMovieDetails(media: film.asMedia, coordinator: moviesCoordinator)
        navigationController?.pushViewController(detailsVC, animated: true)
    }
}
