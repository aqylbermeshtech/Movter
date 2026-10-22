//
//  DefaultProfileStatsRepository.swift
//  Movter
//

import Foundation

final class DefaultProfileStatsRepository: ProfileStatsRepository {

    private let watchlistStore: WatchlistStoring
    private let watchedStore: WatchlistStoring
    private let reviewStore: ReviewStoring

    init(
        watchlistStore: WatchlistStoring,
        watchedStore: WatchlistStoring,
        reviewStore: ReviewStoring
    ) {
        self.watchlistStore = watchlistStore
        self.watchedStore = watchedStore
        self.reviewStore = reviewStore
    }

    func fetchStats() async throws -> ProfileStats {
        async let watchlistItems = watchlistStore.fetchAll()
        async let watchedItems = watchedStore.fetchAll()
        async let reviews = reviewStore.fetchAll()

        let (watchlist, watched, revs) = try await (watchlistItems, watchedItems, reviews)

        return ProfileStats(
            watchedCount: watched.count,
            reviewsCount: revs.count,
            watchlistCount: watchlist.count
        )
    }
}
