//
//  GetExcludedSwipeMediaIDsUseCase.swift
//  Movter
//
//  Created by Nurtore on 20.11.2026.
//

import Foundation

protocol GetExcludedSwipeMediaIDsUseCase {
    func execute() async -> Set<Int>
}

final class DefaultGetExcludedSwipeMediaIDsUseCase: GetExcludedSwipeMediaIDsUseCase {

    private let seenFilmsRepository: SeenFilmsRepository
    private let watchlistRepository: WatchlistRepository
    private let reviewsRepository: ReviewsRepository
    private let topFavoritesRepository: TopFavoritesRepository

    init(
        seenFilmsRepository: SeenFilmsRepository = DefaultSeenFilmsRepository(),
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository(),
        reviewsRepository: ReviewsRepository = DefaultReviewsRepository(),
        topFavoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository()
    ) {
        self.seenFilmsRepository = seenFilmsRepository
        self.watchlistRepository = watchlistRepository
        self.reviewsRepository = reviewsRepository
        self.topFavoritesRepository = topFavoritesRepository
    }

    func execute() async -> Set<Int> {
        var excluded = seenFilmsRepository.fetchSeenIDs()

        let watchlistItems = (try? await watchlistRepository.fetchAll(list: .watchlist)) ?? []
        excluded.formUnion(watchlistItems.map(\.tmdbID))

        let watchedItems = (try? await watchlistRepository.fetchAll(list: .watched)) ?? []
        excluded.formUnion(watchedItems.map(\.tmdbID))

        let reviews = (try? await reviewsRepository.fetchAll()) ?? []
        excluded.formUnion(reviews.compactMap(\.tmdbID))

        let favorites = await topFavoritesRepository.fetchTopFavorites()
        excluded.formUnion(favorites.map(\.id))

        return excluded.filter { $0 > 0 }
    }
}
