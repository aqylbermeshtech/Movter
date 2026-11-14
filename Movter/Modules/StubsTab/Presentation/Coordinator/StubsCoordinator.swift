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
}
