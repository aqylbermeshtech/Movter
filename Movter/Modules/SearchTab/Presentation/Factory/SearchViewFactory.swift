//
//  SearchViewFactory.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
enum SearchViewFactory {

    static func makeSearchHome(
        coordinator: SearchCoordinator? = nil
    ) -> UIViewController {
        let browseUseCase = DefaultGetBrowseCategoriesUseCase()
        let viewModel = SearchMoviesViewModel(getBrowseCategoriesUseCase: browseUseCase)
        let actualCoordinator = coordinator ?? DefaultSearchCoordinator()
        let viewController = SearchMoviesViewController(
            viewModel: viewModel,
            coordinator: actualCoordinator
        )
        if let defaultCoord = actualCoordinator as? DefaultSearchCoordinator, defaultCoord.viewController == nil {
            defaultCoord.viewController = viewController
        }
        return viewController
    }

    static func makeSubcategory(
        title: String,
        items: [String],
        coordinator: SearchCoordinator? = nil
    ) -> UIViewController {
        SubcategoryViewController(
            title: title,
            items: items,
            coordinator: coordinator
        )
    }

    static func makeMovieGrid(
        source: MediaQuerySource,
        title: String,
        coordinator: SearchCoordinator? = nil
    ) -> UIViewController {
        let viewModel = MovieGridViewModel(source: source)
        return MovieGridViewController(
            viewModel: viewModel,
            title: title,
            coordinator: coordinator
        )
    }

    static func makeSearchOverlay(
        coordinator: SearchCoordinator? = nil,
        onSubmit: @escaping (String) -> Void
    ) -> UIViewController {
        let viewModel = SearchOverlayViewModel()
        let viewController = SearchOverlayViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
        viewController.onSubmit = onSubmit
        return viewController
    }
}

