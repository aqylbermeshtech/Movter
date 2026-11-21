import Foundation
@testable import Movter

enum MockRepositoryError: Error, Equatable {
    case forcedFailure
}

final class MockSeenFilmsRepository: SeenFilmsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var seenIDs: Set<Int>
    private(set) var fetchSeenIDsCallCount = 0
    private(set) var markedSeenIDs: [Int] = []

    init(seenIDs: Set<Int> = []) {
        self.seenIDs = seenIDs
    }

    func fetchSeenIDs() -> Set<Int> {
        lock.withLock {
            fetchSeenIDsCallCount += 1
            return seenIDs
        }
    }

    func markSeen(tmdbID: Int) {
        lock.withLock {
            seenIDs.insert(tmdbID)
            markedSeenIDs.append(tmdbID)
        }
    }

    func setSeenIDs(_ ids: Set<Int>) {
        lock.withLock { seenIDs = ids }
    }
}

final class MockWatchlistRepository: WatchlistRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var watchlist: [WatchlistItem]
    private var watched: [WatchlistItem]

    var watchlistFetchError: Error?
    var watchedFetchError: Error?
    var mutationError: Error?

    private(set) var fetchAllCalls: [WatchlistPresentationType] = []
    private(set) var removedWatchlistMediaIDs: [Int] = []

    init(watchlist: [WatchlistItem] = [], watched: [WatchlistItem] = []) {
        self.watchlist = watchlist
        self.watched = watched
    }

    func setItems(_ items: [WatchlistItem], for list: WatchlistPresentationType) {
        lock.withLock {
            switch list {
            case .watchlist: watchlist = items
            case .watched: watched = items
            }
        }
    }

    func fetchAll(list: WatchlistPresentationType) async throws -> [WatchlistItem] {
        try lock.withLock {
            fetchAllCalls.append(list)
            switch list {
            case .watchlist:
                if let watchlistFetchError { throw watchlistFetchError }
                return watchlist
            case .watched:
                if let watchedFetchError { throw watchedFetchError }
                return watched
            }
        }
    }

    func save(_ item: WatchlistItem, to list: WatchlistPresentationType) async throws {
        try lock.withLock {
            if let mutationError { throw mutationError }
            switch list {
            case .watchlist:
                if let idx = watchlist.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                    watchlist[idx] = item
                } else {
                    watchlist.append(item)
                }
            case .watched:
                if let idx = watched.firstIndex(where: { $0.tmdbID == item.tmdbID }) {
                    watched[idx] = item
                } else {
                    watched.append(item)
                }
            }
        }
    }

    func delete(id: UUID, from list: WatchlistPresentationType) async throws {
        try lock.withLock {
            if let mutationError { throw mutationError }
            switch list {
            case .watchlist: watchlist.removeAll { $0.id == id }
            case .watched: watched.removeAll { $0.id == id }
            }
        }
    }

    func isWatchlisted(mediaId: Int) async throws -> Bool {
        lock.withLock { watchlist.contains { $0.tmdbID == mediaId } }
    }

    func isWatched(mediaId: Int) async throws -> Bool {
        lock.withLock { watched.contains { $0.tmdbID == mediaId } }
    }

    func addToWatchlist(_ media: Media) async throws {
        try await save(WatchlistItem(from: media), to: .watchlist)
    }

    func removeFromWatchlist(mediaId: Int) async throws {
        try lock.withLock {
            if let mutationError { throw mutationError }
            removedWatchlistMediaIDs.append(mediaId)
            watchlist.removeAll { $0.tmdbID == mediaId }
        }
    }

    func markAsWatched(_ media: Media) async throws {
        try await save(WatchlistItem(from: media), to: .watched)
    }

    func unmarkAsWatched(mediaId: Int) async throws {
        try lock.withLock {
            if let mutationError { throw mutationError }
            watched.removeAll { $0.tmdbID == mediaId }
        }
    }
}

final class MockReviewsRepository: ReviewsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var reviews: [Review]
    var fetchError: Error?
    var saveError: Error?
    private(set) var fetchAllCallCount = 0

    init(reviews: [Review] = []) {
        self.reviews = reviews
    }

    func setReviews(_ newReviews: [Review]) {
        lock.withLock { reviews = newReviews }
    }

    func fetchAll() async throws -> [Review] {
        try lock.withLock {
            fetchAllCallCount += 1
            if let fetchError { throw fetchError }
            return reviews
        }
    }

    func fetchReview(for mediaId: Int) async throws -> Review? {
        try await fetchAll().first { $0.tmdbID == mediaId }
    }

    func saveReview(_ review: Review) async throws {
        try lock.withLock {
            if let saveError { throw saveError }
            if let idx = reviews.firstIndex(where: { $0.id == review.id }) {
                reviews[idx] = review
            } else {
                reviews.append(review)
            }
        }
    }

    func deleteReview(id: UUID) async throws {
        lock.withLock { reviews.removeAll { $0.id == id } }
    }
}

final class MockTopFavoritesRepository: TopFavoritesRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var favorites: [FavoriteFilm]
    private(set) var fetchCallCount = 0

    init(favorites: [FavoriteFilm] = []) {
        self.favorites = favorites
    }

    func setFavorites(_ films: [FavoriteFilm]) {
        lock.withLock { favorites = films }
    }

    func fetchTopFavorites() async -> [FavoriteFilm] {
        lock.withLock {
            fetchCallCount += 1
            return favorites
        }
    }

    func saveTopFavorites(_ films: [FavoriteFilm]) async {
        lock.withLock { favorites = films }
    }
}

final class MockPopularMoviesRepository: PopularMoviesRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var pages: [Int: MediaPage]
    private var defaultPage: MediaPage
    var error: Error?
    var fetchHandler: (@Sendable (Int) async throws -> MediaPage)?
    private var _requestedPages: [Int] = []

    var requestedPages: [Int] {
        lock.withLock { _requestedPages }
    }

    init(
        items: [Media] = [],
        isLastPage: Bool = true,
        pages: [Int: MediaPage] = [:]
    ) {
        self.defaultPage = MediaPage(items: items, isLastPage: isLastPage)
        self.pages = pages
    }

    func setPages(_ newPages: [Int: MediaPage]) {
        lock.withLock { pages = newPages }
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        let handler: (@Sendable (Int) async throws -> MediaPage)? = lock.withLock {
            _requestedPages.append(page)
            return fetchHandler
        }
        if let handler {
            return try await handler(page)
        }
        return try lock.withLock {
            if let error { throw error }
            return pages[page] ?? defaultPage
        }
    }
}
