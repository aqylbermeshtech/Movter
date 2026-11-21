//
//  SwipeViewFactory.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import UIKit

@MainActor
enum SwipeViewFactory {

    static func makeSwipeDeck(
        coordinator: SwipeCoordinator? = nil,
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository(),
        seenFilmsRepository: SeenFilmsRepository = DefaultSeenFilmsRepository(),
        popularMoviesRepository: PopularMoviesRepository = DefaultPopularMoviesRepository(),
        reviewsRepository: ReviewsRepository = DefaultReviewsRepository(),
        topFavoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository(),
        artworkPrefetcher: HeroArtworkPrefetching? = DefaultHeroArtworkPrefetcher(),
        cardViewFactory: @escaping (Media) -> SwipeCardView = { SwipeCardView(media: $0) }
    ) -> UIViewController {
        let fetchDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularMoviesRepository)
        let swipeCardUseCase = DefaultSwipeCardUseCase(seenFilmsRepository: seenFilmsRepository, watchlistRepository: watchlistRepository)
        let undoSwipeCardUseCase = DefaultUndoSwipeCardUseCase(seenFilmsRepository: seenFilmsRepository, watchlistRepository: watchlistRepository)
        let getExcludedIDsUseCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: seenFilmsRepository,
            watchlistRepository: watchlistRepository,
            reviewsRepository: reviewsRepository,
            topFavoritesRepository: topFavoritesRepository
        )
        let buildTasteProfileUseCase = DefaultBuildUserTasteProfileUseCase(
            topFavoritesRepository: topFavoritesRepository,
            reviewsRepository: reviewsRepository,
            watchlistRepository: watchlistRepository,
            seenFilmsRepository: seenFilmsRepository
        )

        let viewModel = SwipeDeckViewModel(
            fetchDeckUseCase: fetchDeckUseCase,
            swipeCardUseCase: swipeCardUseCase,
            getExcludedIDsUseCase: getExcludedIDsUseCase,
            buildTasteProfileUseCase: buildTasteProfileUseCase,
            undoSwipeCardUseCase: undoSwipeCardUseCase,
            artworkPrefetcher: artworkPrefetcher
        )

        let actualCoordinator = coordinator ?? DefaultSwipeCoordinator()
        let viewController = SwipeDeckViewController(
            viewModel: viewModel,
            coordinator: actualCoordinator,
            cardViewFactory: cardViewFactory
        )
        if let defaultCoord = actualCoordinator as? DefaultSwipeCoordinator, defaultCoord.viewController == nil {
            defaultCoord.viewController = viewController
        }
        return viewController
    }

    static func makeWatchlist(
        presentation: WatchlistPresentationType = .watchlist,
        coordinator: SwipeCoordinator? = nil,
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository()
    ) -> UIViewController {
        let fetchUseCase = DefaultFetchWatchlistUseCase(repository: watchlistRepository)
        let deleteUseCase = DefaultDeleteWatchlistItemUseCase(repository: watchlistRepository)

        let viewModel = WatchlistListViewModel(
            presentation: presentation,
            fetchWatchlistUseCase: fetchUseCase,
            deleteWatchlistItemUseCase: deleteUseCase
        )

        return WatchlistListViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
    }
}

