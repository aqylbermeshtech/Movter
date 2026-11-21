import Foundation
import UIKit
import XCTest
@testable import Movter

final class Task2ExclusionAndReconciliationTests: UserDefaultsTestCase {

    // MARK: - Helpers

    @MainActor
    private func makeHarness(
        seenIDs: Set<Int> = [],
        watchlist: [WatchlistItem] = [],
        watched: [WatchlistItem] = [],
        reviews: [Review] = [],
        favorites: [FavoriteFilm] = [],
        popularItems: [Media] = [],
        popularPages: [Int: MediaPage] = [:],
        isLastPage: Bool = true,
        isOnline: Bool = true
    ) -> (
        vc: SwipeDeckViewController,
        vm: SwipeDeckViewModel,
        seenRepo: MockSeenFilmsRepository,
        watchlistRepo: MockWatchlistRepository,
        reviewsRepo: MockReviewsRepository,
        favoritesRepo: MockTopFavoritesRepository,
        popularRepo: MockPopularMoviesRepository,
        monitor: MockNetworkMonitor
    ) {
        let seenRepo = MockSeenFilmsRepository(seenIDs: seenIDs)
        let watchlistRepo = MockWatchlistRepository(watchlist: watchlist, watched: watched)
        let reviewsRepo = MockReviewsRepository(reviews: reviews)
        let favoritesRepo = MockTopFavoritesRepository(favorites: favorites)
        let popularRepo = MockPopularMoviesRepository(items: popularItems, isLastPage: isLastPage, pages: popularPages)
        let monitor = MockNetworkMonitor(isOnline: isOnline)

        let cursorStore = MockSwipePaginationCursorStore()

        let vm = SwipeDeckViewModel(
            fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo),
            swipeCardUseCase: DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo),
            getExcludedIDsUseCase: DefaultGetExcludedSwipeMediaIDsUseCase(
                seenFilmsRepository: seenRepo,
                watchlistRepository: watchlistRepo,
                reviewsRepository: reviewsRepo,
                topFavoritesRepository: favoritesRepo
            ),
            monitor: monitor,
            paginationCursorStore: cursorStore
        )
        let vc = SwipeDeckViewController(
            viewModel: vm,
            coordinator: MockSwipeCoordinator(),
            cardViewFactory: { SwipeCardView(media: $0, loadRemoteArtwork: false) }
        )
        return (vc, vm, seenRepo, watchlistRepo, reviewsRepo, favoritesRepo, popularRepo, monitor)
    }

    private func waitUntil(
        timeout: TimeInterval = 2.0,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + .milliseconds(Int(timeout * 1000))
        while ContinuousClock.now < deadline {
            if await MainActor.run(body: condition) {
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        let met = await MainActor.run(body: condition)
        XCTAssertTrue(met, "Condition was not met within \(timeout)s")
    }

    // MARK: - F5 Tier 1: Cross-Tab Exclusion

    func test_GetExcludedIDs_ExcludesSeenFilms() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(seenIDs: [10]),
            watchlistRepository: MockWatchlistRepository(),
            reviewsRepository: MockReviewsRepository(),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [10])
    }

    func test_GetExcludedIDs_ExcludesWatchlistItems() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(),
            watchlistRepository: MockWatchlistRepository(
                watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 20)]
            ),
            reviewsRepository: MockReviewsRepository(),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [20])
    }

    func test_GetExcludedIDs_ExcludesWatchedItems() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(),
            watchlistRepository: MockWatchlistRepository(
                watched: [TestFixtures.makeWatchlistItem(tmdbID: 30)]
            ),
            reviewsRepository: MockReviewsRepository(),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [30])
    }

    func test_GetExcludedIDs_ExcludesNonNilReviewedTmdbIDs() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(),
            watchlistRepository: MockWatchlistRepository(),
            reviewsRepository: MockReviewsRepository(
                reviews: [TestFixtures.makeReview(tmdbID: 40)]
            ),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [40])
    }

    func test_GetExcludedIDs_ExcludesTopFavorites_AndSwipeViewFactoryWiresAllRepositories() async throws {
        let seenRepo = MockSeenFilmsRepository(seenIDs: [1])
        let watchlistRepo = MockWatchlistRepository(
            watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 2)],
            watched: [TestFixtures.makeWatchlistItem(tmdbID: 3)]
        )
        let reviewsRepo = MockReviewsRepository(
            reviews: [TestFixtures.makeReview(tmdbID: 4)]
        )
        let favoritesRepo = MockTopFavoritesRepository(
            favorites: [TestFixtures.makeFavoriteFilm(id: 5)]
        )
        let popularRepo = MockPopularMoviesRepository(
            items: [1, 2, 3, 4, 5].map { TestFixtures.makeMedia(id: $0, title: "Film \($0)") },
            isLastPage: true
        )

        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: seenRepo,
            watchlistRepository: watchlistRepo,
            reviewsRepository: reviewsRepo,
            topFavoritesRepository: favoritesRepo
        )
        let directExcluded = await useCase.execute()
        XCTAssertEqual(directExcluded, [1, 2, 3, 4, 5])

        let vc = await MainActor.run {
            let controller = SwipeViewFactory.makeSwipeDeck(
                coordinator: MockSwipeCoordinator(),
                watchlistRepository: watchlistRepo,
                seenFilmsRepository: seenRepo,
                popularMoviesRepository: popularRepo,
                reviewsRepository: reviewsRepo,
                topFavoritesRepository: favoritesRepo,
                cardViewFactory: { SwipeCardView(media: $0, loadRemoteArtwork: false) }
            ) as! SwipeDeckViewController
            controller.loadViewIfNeeded()
            return controller
        }

        try await waitUntil {
            !popularRepo.requestedPages.isEmpty && seenRepo.fetchSeenIDsCallCount >= 2
        }

        await MainActor.run {
            XCTAssertTrue(vc.cardViews.isEmpty)
        }
        XCTAssertTrue(watchlistRepo.fetchAllCalls.contains(.watchlist))
        XCTAssertTrue(watchlistRepo.fetchAllCalls.contains(.watched))
        XCTAssertGreaterThanOrEqual(reviewsRepo.fetchAllCallCount, 1)
        XCTAssertGreaterThanOrEqual(favoritesRepo.fetchCallCount, 1)
    }

    // MARK: - F5 Tier 2: Boundary & Fault-Isolation Cases

    func test_GetExcludedIDs_WhenAllRepositoriesEmpty_ReturnsEmptySet() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(),
            watchlistRepository: MockWatchlistRepository(),
            reviewsRepository: MockReviewsRepository(),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertTrue(result.isEmpty)
    }

    func test_GetExcludedIDs_ReviewWithNilTmdbID_IsSkipped() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(),
            watchlistRepository: MockWatchlistRepository(),
            reviewsRepository: MockReviewsRepository(reviews: [
                TestFixtures.makeReview(tmdbID: nil),
                TestFixtures.makeReview(tmdbID: 42)
            ]),
            topFavoritesRepository: MockTopFavoritesRepository()
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [42])
    }

    func test_GetExcludedIDs_DuplicateIDsAcrossAllRepositories_AreDeduplicated() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(seenIDs: [77]),
            watchlistRepository: MockWatchlistRepository(
                watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 77)],
                watched: [TestFixtures.makeWatchlistItem(tmdbID: 77)]
            ),
            reviewsRepository: MockReviewsRepository(
                reviews: [TestFixtures.makeReview(tmdbID: 77)]
            ),
            topFavoritesRepository: MockTopFavoritesRepository(
                favorites: [TestFixtures.makeFavoriteFilm(id: 77)]
            )
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [77])
    }

    func test_GetExcludedIDs_ThrowingRepositories_DoNotBlockSurvivingRepositories() async {
        let watchlistRepo = MockWatchlistRepository(
            watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 99)],
            watched: [TestFixtures.makeWatchlistItem(tmdbID: 2)]
        )
        watchlistRepo.watchlistFetchError = MockRepositoryError.forcedFailure

        let reviewsRepo = MockReviewsRepository(
            reviews: [TestFixtures.makeReview(tmdbID: 88)]
        )
        reviewsRepo.fetchError = MockRepositoryError.forcedFailure

        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(seenIDs: [1]),
            watchlistRepository: watchlistRepo,
            reviewsRepository: reviewsRepo,
            topFavoritesRepository: MockTopFavoritesRepository(
                favorites: [TestFixtures.makeFavoriteFilm(id: 3)]
            )
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [1, 2, 3])
    }

    func test_GetExcludedIDs_NonPositiveIDs_HandledSafely() async {
        let useCase = DefaultGetExcludedSwipeMediaIDsUseCase(
            seenFilmsRepository: MockSeenFilmsRepository(seenIDs: [0, -1, 55]),
            watchlistRepository: MockWatchlistRepository(
                watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 0)]
            ),
            reviewsRepository: MockReviewsRepository(
                reviews: [TestFixtures.makeReview(tmdbID: -10)]
            ),
            topFavoritesRepository: MockTopFavoritesRepository(
                favorites: [TestFixtures.makeFavoriteFilm(id: 0)]
            )
        )

        let result = await useCase.execute()
        XCTAssertEqual(result, [55])
    }

    // MARK: - F6 Tier 1: Queue Reconciliation & Sync

    func test_ViewModel_ReconcileQueue_RemovesNewlyWatchlistedFrontCard() async throws {
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { harness.vm.peek(5).map(\.id) == [1, 2, 3] }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 1), to: .watchlist)
        await harness.vm.performQueueReconciliation()

        let remaining = await MainActor.run { harness.vm.peek(5).map(\.id) }
        XCTAssertEqual(remaining, [2, 3])
    }

    func test_ViewModel_ReconcileQueue_RemovesNewlyWatchedReviewedOrFavoritedMiddleCardsPreservingOrder() async throws {
        let items = TestFixtures.makeMediaList(count: 5, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { harness.vm.peek(5).map(\.id) == [1, 2, 3, 4, 5] }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 2), to: .watched)
        try await harness.reviewsRepo.saveReview(TestFixtures.makeReview(tmdbID: 3))
        await harness.favoritesRepo.saveTopFavorites([TestFixtures.makeFavoriteFilm(id: 4)])

        await harness.vm.performQueueReconciliation()

        let remaining = await MainActor.run { harness.vm.peek(5).map(\.id) }
        XCTAssertEqual(remaining, [1, 5])
    }

    func test_SwipeDeckVC_SyncCardsFromQueue_RemovesStaleCardViewFromCardViewsAndSuperview() async throws {
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        let removedFrontCard = await MainActor.run { harness.vc.cardViews[0] }
        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 1), to: .watchlist)
        await harness.vm.performQueueReconciliation()

        await MainActor.run {
            XCTAssertNil(removedFrontCard.superview)
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [2, 3])
        }
    }

    func test_SwipeDeckVC_ViewWillAppear_InvokesQueueReconciliation() async throws {
        let items = [10, 20].map { TestFixtures.makeMedia(id: $0, title: "Film \($0)") }
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [10, 20] }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 10), to: .watchlist)
        await MainActor.run {
            harness.vc.viewWillAppear(false)
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [20] }
    }

    func test_ViewModel_ReconcileQueue_DroppingToOrBelowPrefetchThreshold_TriggersFetchNextPage() async throws {
        let page1 = MediaPage(items: TestFixtures.makeMediaList(count: 5, startingID: 1), isLastPage: false)
        let page2 = MediaPage(items: TestFixtures.makeMediaList(count: 2, startingID: 6), isLastPage: true)
        let harness = await MainActor.run {
            let h = makeHarness(popularPages: [1: page1, 2: page2])
            h.vm.start()
            return h
        }

        try await waitUntil { harness.vm.queue.map(\.id) == [1, 2, 3, 4, 5] }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 2), to: .watchlist)
        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 3), to: .watchlist)
        await harness.vm.performQueueReconciliation()

        try await waitUntil {
            harness.popularRepo.requestedPages == [1, 2] &&
            harness.vm.queue.map(\.id) == [1, 4, 5, 6, 7]
        }
    }

    // MARK: - F6 Tier 2: Boundary & Edge Cases

    func test_ViewModel_ReconcileQueue_WhenQueueEmpty_UpdatesExclusionsWithoutCrashing() async throws {
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: [], isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { !harness.popularRepo.requestedPages.isEmpty && !harness.vm.isFetching }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 99), to: .watchlist)
        await harness.vm.performQueueReconciliation()

        await MainActor.run {
            XCTAssertTrue(harness.vm.queue.isEmpty)
            XCTAssertTrue(harness.vm.excludedIDs.contains(99))
        }
    }

    func test_ViewModel_ReconcileQueue_WhenAllQueuedCardsExcluded_ClearsQueueAndCardViews() async throws {
        let items = TestFixtures.makeMediaList(count: 2, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2] }
        let oldCards = await MainActor.run { harness.vc.cardViews }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 1), to: .watchlist)
        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 2), to: .watched)
        await harness.vm.performQueueReconciliation()

        await MainActor.run {
            XCTAssertTrue(harness.vm.queue.isEmpty)
            XCTAssertTrue(harness.vc.cardViews.isEmpty)
            for card in oldCards {
                XCTAssertNil(card.superview)
            }
        }
    }

    func test_SwipeDeckVC_ViewWillAppearWhileFetching_DoesNotDuplicateFetchOrCorruptQueue() async throws {
        let gate = AsyncFetchGate()
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.popularRepo.fetchHandler = { _ in
                await gate.enterAndWait()
                return MediaPage(items: items, isLastPage: true)
            }
            h.vc.loadViewIfNeeded()
            return h
        }

        await gate.waitUntilEntered()
        await MainActor.run {
            harness.vc.viewWillAppear(false)
        }
        XCTAssertEqual(harness.popularRepo.requestedPages, [1])

        await gate.resume()

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }
        XCTAssertEqual(harness.popularRepo.requestedPages, [1])
    }

    func test_ViewModel_ReconcileQueue_WhenSessionComplete_RemovesExcludedCardsWithoutFetching() async throws {
        let page1 = MediaPage(items: TestFixtures.makeMediaList(count: 12, startingID: 1), isLastPage: false)
        let page2 = MediaPage(items: TestFixtures.makeMediaList(count: 3, startingID: 13), isLastPage: true)
        let harness = await MainActor.run {
            let h = makeHarness(popularPages: [1: page1, 2: page2])
            h.vm.start()
            return h
        }

        try await waitUntil { harness.vm.queue.count == 12 }

        await MainActor.run {
            for _ in 0..<SwipeDeckViewModel.sessionCardLimit {
                harness.vm.consumeFrontCard(direction: .pass)
            }
            XCTAssertTrue(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.queue.map(\.id), [11, 12])
        }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 11), to: .watched)
        await harness.vm.performQueueReconciliation()

        await MainActor.run {
            XCTAssertEqual(harness.vm.queue.map(\.id), [12])
        }
        XCTAssertEqual(harness.popularRepo.requestedPages, [1])
    }

    @MainActor
    func test_SwipeDeckVC_SyncCardsFromQueue_RepeatedCalls_AreIdempotent() {
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = makeHarness(popularItems: items, isLastPage: true)
        harness.vc.loadViewIfNeeded()

        let exp = expectation(description: "Initial load")
        harness.vm.onQueueChange = {
            harness.vc.syncCardsFromQueue()
            if harness.vc.cardViews.count == 3 {
                harness.vm.onQueueChange = nil
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 2.0)

        let initialCardIDs = harness.vc.cardViews.map(\.media.id)
        let initialInstances = harness.vc.cardViews

        harness.vc.syncCardsFromQueue()
        harness.vc.syncCardsFromQueue()
        harness.vc.syncCardsFromQueue()

        XCTAssertEqual(harness.vc.cardViews.map(\.media.id), initialCardIDs)
        XCTAssertEqual(harness.vc.cardViews.count, 3)
        for (idx, card) in harness.vc.cardViews.enumerated() {
            XCTAssertTrue(card === initialInstances[idx])
        }
    }
}

private actor AsyncFetchGate {
    private var entered = false
    private var enterWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    func enterAndWait() async {
        entered = true
        enterWaiter?.resume()
        enterWaiter = nil
        await withCheckedContinuation { continuation in
            releaseWaiter = continuation
        }
    }

    func waitUntilEntered() async {
        if entered { return }
        await withCheckedContinuation { continuation in
            enterWaiter = continuation
        }
    }

    func resume() {
        releaseWaiter?.resume()
        releaseWaiter = nil
    }
}
