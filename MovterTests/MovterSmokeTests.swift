import Foundation
import UIKit
import XCTest
@testable import Movter

final class MovterSmokeTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let name = "com.nurtore.movter.tests.\(UUID().uuidString)"
        suiteName = name
        defaults = try XCTUnwrap(UserDefaults(suiteName: name))
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    @MainActor
    func testAppHostBundleAndSwipeFactoryInstantiate() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.nurtore.MovieListApp")

        let dataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults)
        let seenRepo = DefaultSeenFilmsRepository(localDataSource: dataSource)
        let vc = SwipeViewFactory.makeSwipeDeck(
            watchlistRepository: StubWatchlistRepository(),
            seenFilmsRepository: seenRepo,
            popularMoviesRepository: StubPopularMoviesRepository(items: [])
        )
        XCTAssertTrue(vc is SwipeDeckViewController)
    }

    func testSeenFilmsRepositoryPersistsAndMediaComputesFields() {
        let media = Self.makeMedia(id: 101, title: "Dune: Part Two", releaseDate: "2024-02-27")
        XCTAssertEqual(media.displayName, "Dune: Part Two")
        XCTAssertEqual(media.year, "2024")
        XCTAssertEqual(media.mediaType, .movie)

        let dataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults)
        let repository = DefaultSeenFilmsRepository(localDataSource: dataSource)
        XCTAssertTrue(repository.fetchSeenIDs().isEmpty)

        repository.markSeen(tmdbID: media.id)
        XCTAssertEqual(repository.fetchSeenIDs(), [101])
    }

    func testFetchDeckExcludesSeenAndSwipeCardLikesIntoWatchlist() async throws {
        let m1 = Self.makeMedia(id: 1, title: "Excluded")
        let m2 = Self.makeMedia(id: 2, title: "Included")
        let popularRepo = StubPopularMoviesRepository(items: [m1, m2])
        let fetchUseCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo)

        let deck = try await fetchUseCase.execute(page: 1, excludingIDs: [1])
        XCTAssertEqual(deck.items.map(\.id), [2])

        let seenRepo = DefaultSeenFilmsRepository(
            localDataSource: UserDefaultsSeenFilmsDataSource(defaults: defaults)
        )
        let watchlistRepo = StubWatchlistRepository()
        let swipeUseCase = DefaultSwipeCardUseCase(
            seenFilmsRepository: seenRepo,
            watchlistRepository: watchlistRepo
        )

        try await swipeUseCase.execute(media: m2, direction: .like)
        XCTAssertTrue(seenRepo.fetchSeenIDs().contains(2))
        let saved = try await watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertEqual(saved.map(\.tmdbID), [2])
    }

    func testSwipeDeckViewModelLoadsAndConsumesCard() async throws {
        let m1 = Self.makeMedia(id: 10, title: "Film A")
        let m2 = Self.makeMedia(id: 20, title: "Film B")
        let popularRepo = StubPopularMoviesRepository(items: [m1, m2])
        let seenRepo = DefaultSeenFilmsRepository(
            localDataSource: UserDefaultsSeenFilmsDataSource(defaults: defaults)
        )
        let watchlistRepo = StubWatchlistRepository()

        let loaded = expectation(description: "Deck loaded")
        let vm = await MainActor.run {
            let viewModel = SwipeDeckViewModel(
                fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo),
                swipeCardUseCase: DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo),
                getSeenIDsUseCase: DefaultGetSeenFilmIDsUseCase(repository: seenRepo),
                monitor: StubNetworkMonitor(isOnline: true)
            )
            viewModel.onQueueChange = { [weak viewModel] in
                guard let viewModel, !viewModel.peek(5).isEmpty else { return }
                viewModel.onQueueChange = nil
                loaded.fulfill()
            }
            viewModel.start()
            return viewModel
        }

        await fulfillment(of: [loaded], timeout: 2.0)

        await MainActor.run {
            XCTAssertEqual(vm.peek(5).map(\.id), [10, 20])
            vm.consumeFrontCard(direction: .pass)
            XCTAssertEqual(vm.sessionSwipeCount, 1)
            XCTAssertEqual(vm.peek(5).map(\.id), [20])
        }

        let deadline = ContinuousClock.now + .seconds(1)
        while !seenRepo.fetchSeenIDs().contains(10), ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(10))
        }
        withExtendedLifetime(vm) {}
        XCTAssertTrue(seenRepo.fetchSeenIDs().contains(10))
    }

    private static func makeMedia(
        id: Int,
        title: String,
        releaseDate: String? = "2024-01-01"
    ) -> Media {
        Media(
            id: id,
            title: title,
            name: nil,
            overview: "Overview",
            posterPath: "/poster.jpg",
            backdropPath: nil,
            releaseDate: releaseDate,
            firstAirDate: nil,
            voteAverage: 7.5,
            voteCount: 500,
            genreIds: [28]
        )
    }
}

private final class StubPopularMoviesRepository: PopularMoviesRepository {
    private let items: [Media]

    init(items: [Media]) {
        self.items = items
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        MediaPage(items: items, isLastPage: true)
    }
}

private final class StubWatchlistRepository: WatchlistRepository {
    private var watchlist: [WatchlistItem] = []
    private var watched: [WatchlistItem] = []

    func fetchAll(list: WatchlistPresentationType) async throws -> [WatchlistItem] {
        switch list {
        case .watchlist: return watchlist
        case .watched: return watched
        }
    }

    func save(_ item: WatchlistItem, to list: WatchlistPresentationType) async throws {
        switch list {
        case .watchlist:
            if !watchlist.contains(where: { $0.tmdbID == item.tmdbID }) {
                watchlist.append(item)
            }
        case .watched:
            if !watched.contains(where: { $0.tmdbID == item.tmdbID }) {
                watched.append(item)
            }
        }
    }

    func delete(id: UUID, from list: WatchlistPresentationType) async throws {
        switch list {
        case .watchlist:
            watchlist.removeAll { $0.id == id }
        case .watched:
            watched.removeAll { $0.id == id }
        }
    }

    func isWatchlisted(mediaId: Int) async throws -> Bool {
        watchlist.contains { $0.tmdbID == mediaId }
    }

    func isWatched(mediaId: Int) async throws -> Bool {
        watched.contains { $0.tmdbID == mediaId }
    }

    func addToWatchlist(_ media: Media) async throws {
        try await save(WatchlistItem(from: media), to: .watchlist)
    }

    func removeFromWatchlist(mediaId: Int) async throws {
        watchlist.removeAll { $0.tmdbID == mediaId }
    }

    func markAsWatched(_ media: Media) async throws {
        try await save(WatchlistItem(from: media), to: .watched)
    }

    func unmarkAsWatched(mediaId: Int) async throws {
        watched.removeAll { $0.tmdbID == mediaId }
    }
}

private final class StubNetworkMonitor: NetworkMonitoring {
    var isOnline: Bool

    init(isOnline: Bool) {
        self.isOnline = isOnline
    }
}
