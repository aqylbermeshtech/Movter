//
//  StubsCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol StubsCoordinator: AnyObject {
    func showAllStubs()
    func showTicketDetails(for review: Review)
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
}
