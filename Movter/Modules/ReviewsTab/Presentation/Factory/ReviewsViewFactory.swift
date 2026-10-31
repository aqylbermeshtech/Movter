//
//  ReviewsViewFactory.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
enum ReviewsViewFactory {

    static func makeReviewsList(
        navigationController: UINavigationController? = nil,
        repository: ReviewsRepository = DefaultReviewsRepository()
    ) -> UIViewController {
        let fetchUseCase = DefaultFetchReviewsUseCase(repository: repository)
        let deleteUseCase = DefaultDeleteReviewUseCase(repository: repository)
        let statsUseCase = DefaultCalculateReviewStatsUseCase()

        let viewModel = ReviewsListViewModel(
            fetchReviewsUseCase: fetchUseCase,
            deleteReviewUseCase: deleteUseCase,
            calculateStatsUseCase: statsUseCase
        )

        let coordinator = DefaultReviewsCoordinator(navigationController: navigationController)
        let viewController = ReviewsListViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
        coordinator.viewController = viewController
        return viewController
    }

    static func makeReviewEditor(
        review: Review?,
        coordinator: ReviewsCoordinator? = nil,
        repository: ReviewsRepository = DefaultReviewsRepository(),
        onSave: (() -> Void)? = nil
    ) -> UIViewController {
        let saveUseCase = DefaultSaveReviewUseCase(repository: repository)
        let viewModel = ReviewEditorViewModel(
            saveReviewUseCase: saveUseCase,
            mode: review.map { .edit($0) } ?? .create
        )
        let viewController = ReviewEditorViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
        viewController.onSave = onSave
        return viewController
    }

    static func makeFilmPicker(
        coordinator: ReviewsCoordinator? = nil,
        searchRepository: FilmSearchRepository = DefaultFilmSearchRepository(),
        onSelect: @escaping (FilmSelection) -> Void
    ) -> UIViewController {
        let searchUseCase = DefaultSearchFilmsForReviewUseCase(repository: searchRepository)
        let viewModel = FilmPickerViewModel(searchFilmsUseCase: searchUseCase)
        let viewController = FilmPickerViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
        viewController.onSelect = onSelect
        return viewController
    }

    static func makeTicket(review: Review) -> UIViewController {
        TicketViewController(review: review)
    }
}
