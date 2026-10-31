//
//  ReviewsCoordinator.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
protocol ReviewsCoordinator: AnyObject {
    func showReviewEditor(for review: Review?, onSave: (() -> Void)?)
    func showFilmPicker(onSelect: @escaping (FilmSelection) -> Void)
    func showTicket(for review: Review)
    func dismiss()
}

@MainActor
final class DefaultReviewsCoordinator: ReviewsCoordinator {

    weak var navigationController: UINavigationController?
    weak var viewController: UIViewController?

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

    func showReviewEditor(for review: Review?, onSave: (() -> Void)?) {
        let editorVC = ReviewsViewFactory.makeReviewEditor(
            review: review,
            coordinator: self,
            onSave: onSave
        )
        let nav = UINavigationController(rootViewController: editorVC)
        activePresenter?.present(nav, animated: true)
    }

    func showFilmPicker(onSelect: @escaping (FilmSelection) -> Void) {
        let pickerVC = ReviewsViewFactory.makeFilmPicker(
            coordinator: self,
            onSelect: onSelect
        )
        let nav = UINavigationController(rootViewController: pickerVC)
        activePresenter?.present(nav, animated: true)
    }

    func showTicket(for review: Review) {
        let ticketVC = ReviewsViewFactory.makeTicket(review: review)
        let nav = UINavigationController(rootViewController: ticketVC)
        activePresenter?.present(nav, animated: true)
    }

    func dismiss() {
        activePresenter?.dismiss(animated: true)
    }
}

