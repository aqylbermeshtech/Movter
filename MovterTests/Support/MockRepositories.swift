import Foundation
@testable import Movter

enum MockRepositoryError: Error, Equatable {
    case forcedFailure
}

final class MockSeenFilmsRepository: SeenFilmsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var seenIDs: Set<Int>
    private var entries: [Int: SwipeHistoryEntry]
    private(set) var fetchSeenIDsCallCount = 0
    private(set) var markedSeenIDs: [Int] = []
    private(set) var recordedSwipes: [(tmdbID: Int, direction: SwipeDirection, date: Date)] = []

    init(seenIDs: Set<Int> = [], entries: [Int: SwipeHistoryEntry] = [:]) {
        self.seenIDs = seenIDs
        var initialEntries = entries
        for id in seenIDs where id > 0 && initialEntries[id] == nil {
            initialEntries[id] = SwipeHistoryEntry(
                tmdbID: id,
                lastDirection: .like,
                updatedAt: Date(timeIntervalSince1970: 0),
                passCount: 0
            )
        }
        self.entries = initialEntries
    }

    func fetchSeenIDs() -> Set<Int> {
        lock.withLock {
            fetchSeenIDsCallCount += 1
            return seenIDs.filter { $0 <= 0 }.union(fetchExcludedIDsUnlocked(asOf: Date()))
        }
    }

    func fetchExcludedIDs(asOf now: Date) -> Set<Int> {
        lock.withLock {
            fetchExcludedIDsUnlocked(asOf: now)
        }
    }

    func fetchHistoryEntries() -> [Int: SwipeHistoryEntry] {
        lock.withLock { entries }
    }

    func markSeen(tmdbID: Int) {
        lock.withLock {
            markedSeenIDs.append(tmdbID)
            recordSwipeUnlocked(tmdbID: tmdbID, direction: .like, at: Date())
        }
    }

    func recordSwipe(tmdbID: Int, direction: SwipeDirection, at date: Date) {
        lock.withLock {
            recordedSwipes.append((tmdbID: tmdbID, direction: direction, date: date))
            recordSwipeUnlocked(tmdbID: tmdbID, direction: direction, at: date)
        }
    }

    func removeSwipeRecord(tmdbID: Int) {
        lock.withLock {
            seenIDs.remove(tmdbID)
            entries.removeValue(forKey: tmdbID)
        }
    }

    func setSeenIDs(_ ids: Set<Int>) {
        lock.withLock {
            seenIDs = ids
            var updated: [Int: SwipeHistoryEntry] = [:]
            for id in ids where id > 0 {
                updated[id] = entries[id] ?? SwipeHistoryEntry(
                    tmdbID: id,
                    lastDirection: .like,
                    updatedAt: Date(timeIntervalSince1970: 0),
                    passCount: 0
                )
            }
            entries = updated
        }
    }

    private func recordSwipeUnlocked(tmdbID: Int, direction: SwipeDirection, at date: Date) {
        guard tmdbID > 0 else { return }
        seenIDs.insert(tmdbID)
        let existing = entries[tmdbID]
        switch direction {
        case .like:
            entries[tmdbID] = SwipeHistoryEntry(
                tmdbID: tmdbID,
                lastDirection: .like,
                updatedAt: date,
                passCount: existing?.passCount ?? 0
            )
        case .pass:
            entries[tmdbID] = SwipeHistoryEntry(
                tmdbID: tmdbID,
                lastDirection: .pass,
                updatedAt: date,
                passCount: (existing?.passCount ?? 0) + 1
            )
        }
    }

    private func fetchExcludedIDsUnlocked(asOf now: Date) -> Set<Int> {
        var excluded: Set<Int> = []
        for entry in entries.values where entry.tmdbID > 0 {
            switch entry.lastDirection {
            case .like:
                excluded.insert(entry.tmdbID)
            case .pass:
                if entry.passCount >= 2 {
                    excluded.insert(entry.tmdbID)
                } else if entry.passCount == 1,
                          now.timeIntervalSince(entry.updatedAt) < DefaultSeenFilmsRepository.passCooldownInterval {
                    excluded.insert(entry.tmdbID)
                }
            }
        }
        return excluded
    }
}

final class MockSwipePaginationCursorStore: SwipePaginationCursorStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var cursor: Int
    private(set) var savedCursors: [Int] = []

    init(initialCursor: Int = UserDefaultsSwipePaginationCursorStore.defaultPage) {
        self.cursor = Self.normalizedPage(initialCursor)
    }

    func loadPageCursor() -> Int {
        lock.withLock { cursor }
    }

    func savePageCursor(_ page: Int) {
        lock.withLock {
            let normalized = Self.normalizedPage(page)
            cursor = normalized
            savedCursors.append(normalized)
        }
    }

    private static func normalizedPage(_ page: Int) -> Int {
        if page < UserDefaultsSwipePaginationCursorStore.defaultPage || page > UserDefaultsSwipePaginationCursorStore.maxPage {
            return UserDefaultsSwipePaginationCursorStore.defaultPage
        }
        return page
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
    var discoverPagesByPath: [String: [Int: MediaPage]] = [:]
    var discoverPages: [Int: MediaPage] = [:]
    var discoverQueryHandler: (@Sendable (DiscoverQuery, Int) async throws -> MediaPage)?
    var similarByID: [Int: [Media]] = [:]
    var similarHandler: (@Sendable (Int) async throws -> [Media])?
    var discoverError: Error?
    var similarError: Error?
    private var _requestedPages: [Int] = []
    private var _requestedDiscoverQueries: [(path: String, queryItems: [URLQueryItem], page: Int)] = []
    private var _requestedSimilarIDs: [Int] = []

    var requestedPages: [Int] {
        lock.withLock { _requestedPages }
    }

    var requestedDiscoverQueries: [(path: String, queryItems: [URLQueryItem], page: Int)] {
        lock.withLock { _requestedDiscoverQueries }
    }

    var requestedSimilarIDs: [Int] {
        lock.withLock { _requestedSimilarIDs }
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

    func fetchDiscoverMovies(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        let handler: (@Sendable (DiscoverQuery, Int) async throws -> MediaPage)? = lock.withLock {
            _requestedDiscoverQueries.append((path: query.path, queryItems: query.queryItems, page: page))
            return discoverQueryHandler
        }
        if let handler {
            return try await handler(query, page)
        }
        return try lock.withLock {
            if let discoverError { throw discoverError }
            if let pathPages = discoverPagesByPath[query.path], let matched = pathPages[page] {
                return matched
            }
            if let fallback = discoverPages[page] {
                return fallback
            }
            return MediaPage(items: [], isLastPage: true)
        }
    }

    func fetchSimilarMovies(for movieID: Int) async throws -> [Media] {
        let handler: (@Sendable (Int) async throws -> [Media])? = lock.withLock {
            _requestedSimilarIDs.append(movieID)
            return similarHandler
        }
        if let handler {
            return try await handler(movieID)
        }
        return try lock.withLock {
            if let similarError { throw similarError }
            return similarByID[movieID] ?? []
        }
    }
}
