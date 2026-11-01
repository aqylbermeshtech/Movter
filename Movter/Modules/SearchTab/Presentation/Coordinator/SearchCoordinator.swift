//
//  SearchCoordinator.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
protocol SearchCoordinator: AnyObject {
    func showSubcategory(title: String, items: [String])
    func showMovieGrid(source: MediaQuerySource, title: String)
    func showMovieDetails(media: Media, from sourceVC: UIViewController & PosterTransitionSource)
    func presentSearchOverlay(onSubmit: @escaping (String) -> Void)
    func dismiss()
}

@MainActor
final class DefaultSearchCoordinator: SearchCoordinator {

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

    func showSubcategory(title: String, items: [String]) {
        let subcategoryVC = SearchViewFactory.makeSubcategory(title: title, items: items, coordinator: self)
        activeNavController?.pushViewController(subcategoryVC, animated: true)
    }

    func showMovieGrid(source: MediaQuerySource, title: String) {
        let gridVC = SearchViewFactory.makeMovieGrid(source: source, title: title, coordinator: self)
        activeNavController?.pushViewController(gridVC, animated: true)
    }

    func showMovieDetails(media: Media, from sourceVC: UIViewController & PosterTransitionSource) {
        let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
        posterTransition.push(detailVC, for: media, from: sourceVC)
    }

    func presentSearchOverlay(onSubmit: @escaping (String) -> Void) {
        let overlayVC = SearchViewFactory.makeSearchOverlay(coordinator: self, onSubmit: onSubmit)
        overlayVC.modalPresentationStyle = .fullScreen
        activePresenter?.present(overlayVC, animated: true)
    }

    func dismiss() {
        activePresenter?.dismiss(animated: true)
    }
}
