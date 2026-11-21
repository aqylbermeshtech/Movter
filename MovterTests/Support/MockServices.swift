import Foundation
import UIKit
@testable import Movter

final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _isOnline: Bool

    var isOnline: Bool {
        get { lock.withLock { _isOnline } }
        set { lock.withLock { _isOnline = newValue } }
    }

    init(isOnline: Bool = true) {
        self._isOnline = isOnline
    }
}

final class MockMediaFetching: MediaFetching, @unchecked Sendable {
    private let lock = NSLock()

    var popularPages: [Int: MediaPage] = [:]
    var discoverPages: [Int: MediaPage] = [:]
    var similarByID: [Int: [Media]] = [:]
    var genresByType: [MediaType: [GenreListResponse.Genre]] = [:]
    var error: Error?

    private(set) var requestedPopularPages: [Int] = []
    private(set) var requestedDiscoverPaths: [String] = []
    private(set) var requestedSimilarIDs: [Int] = []

    func fetchVideo(for id: Int, type: MediaType) async throws -> String? {
        try lock.withLock { if let error { throw error }; return nil }
    }

    func fetchCredits(for id: Int, type: MediaType) async throws -> MovieCredits {
        try lock.withLock { if let error { throw error }; return MovieCredits(cast: [], crew: nil) }
    }

    func fetchSimilar(for id: Int, type: MediaType) async throws -> [Media] {
        try lock.withLock {
            requestedSimilarIDs.append(id)
            if let error { throw error }
            return similarByID[id] ?? []
        }
    }

    func fetchGenres(type: MediaType) async throws -> [GenreListResponse.Genre] {
        try lock.withLock {
            if let error { throw error }
            return genresByType[type] ?? []
        }
    }

    func fetchPersonDetails(for id: Int) async throws -> PersonDetails {
        try lock.withLock {
            if let error { throw error }
            return PersonDetails(
                id: id, name: "Person", biography: nil, birthday: nil,
                deathday: nil, placeOfBirth: nil, profilePath: nil, knownForDepartment: nil
            )
        }
    }

    func fetchPersonCredits(for id: Int) async throws -> [PersonCredit] {
        try lock.withLock { if let error { throw error }; return [] }
    }

    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        try lock.withLock {
            requestedDiscoverPaths.append(query.path)
            if let error { throw error }
            return discoverPages[page] ?? MediaPage(items: [], isLastPage: true)
        }
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        try lock.withLock {
            requestedPopularPages.append(page)
            if let error { throw error }
            return popularPages[page] ?? MediaPage(items: [], isLastPage: true)
        }
    }

    func searchMovies(query: String, page: Int) async throws -> MediaPage {
        try lock.withLock {
            if let error { throw error }
            return MediaPage(items: [], isLastPage: true)
        }
    }
}

final class MockGenreProvider: GenreProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var genres: [Int: String]

    init(genres: [Int: String] = [
        28: "Action", 12: "Adventure", 16: "Animation",
        35: "Comedy", 18: "Drama", 27: "Horror",
        53: "Thriller", 878: "Science Fiction", 99: "Documentary"
    ]) {
        self.genres = genres
    }

    func primaryGenreName(for ids: [Int]?, type: MediaType, completion: @escaping (String?) -> Void) {
        let resolved: String? = lock.withLock {
            guard let ids else { return nil }
            return ids.compactMap { genres[$0] }.first
        }
        completion(resolved)
    }
}

@MainActor
final class MockSwipeCoordinator: SwipeCoordinator {
    private(set) var showWatchlistCallCount = 0
    private(set) var shownDetailsMediaIDs: [Int] = []
    private(set) var dismissCallCount = 0

    func showWatchlist() {
        showWatchlistCallCount += 1
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        shownDetailsMediaIDs.append(media.id)
    }

    func dismiss() {
        dismissCallCount += 1
    }
}

/// Standalone in-memory hero artwork stub for B1; ready to conform to B3's HeroArtworkProviding protocol.
final class MockHeroArtworkLoader: @unchecked Sendable {
    private let lock = NSLock()
    private var artworkByID: [Int: HeroArtwork]
    private(set) var requestedIDs: [(id: Int, type: MediaType)] = []

    init(artworkByID: [Int: HeroArtwork] = [:]) {
        self.artworkByID = artworkByID
    }

    func fetchHeroArtwork(for id: Int, type: MediaType) async -> HeroArtwork {
        lock.withLock {
            requestedIDs.append((id, type))
            return artworkByID[id] ?? HeroArtwork(textlessPosterPath: nil, logoPath: nil)
        }
    }
}
