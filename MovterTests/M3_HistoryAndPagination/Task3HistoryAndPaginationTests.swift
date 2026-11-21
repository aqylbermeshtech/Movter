import Foundation
import XCTest
@testable import Movter

final class Task3HistoryAndPaginationTests: UserDefaultsTestCase {

    // MARK: - Helpers

    private func makeRepository(userID: String? = nil) -> DefaultSeenFilmsRepository {
        let dataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults, userIDProvider: { userID })
        return DefaultSeenFilmsRepository(localDataSource: dataSource)
    }

    private func makeCursorStore(userID: String? = nil) -> UserDefaultsSwipePaginationCursorStore {
        UserDefaultsSwipePaginationCursorStore(defaults: defaults, userIDProvider: { userID })
    }

    @MainActor
    private func makeViewModel(
        seenRepo: SeenFilmsRepository = MockSeenFilmsRepository(),
        watchlistRepo: WatchlistRepository = MockWatchlistRepository(),
        popularRepo: PopularMoviesRepository = MockPopularMoviesRepository(),
        cursorStore: SwipePaginationCursorStoring = MockSwipePaginationCursorStore(),
        monitor: NetworkMonitoring = MockNetworkMonitor(isOnline: true)
    ) -> SwipeDeckViewModel {
        SwipeDeckViewModel(
            fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo),
            swipeCardUseCase: DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo),
            getExcludedIDsUseCase: DefaultGetExcludedSwipeMediaIDsUseCase(
                seenFilmsRepository: seenRepo,
                watchlistRepository: watchlistRepo,
                reviewsRepository: MockReviewsRepository(),
                topFavoritesRepository: MockTopFavoritesRepository()
            ),
            monitor: monitor,
            paginationCursorStore: cursorStore
        )
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

    // MARK: - Legacy Migration & Undo

    func test_LegacyMigration_MigratesPositiveIDsAsLikeAndIgnoresNonPositiveIDs() {
        defaults.set([0, -5, 10, 20], forKey: "com.nurtore.movter.seenFilms.local")

        let dataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults)
        let repo = DefaultSeenFilmsRepository(localDataSource: dataSource)

        let entries = repo.fetchHistoryEntries()
        XCTAssertEqual(entries.keys.sorted(), [10, 20])
        XCTAssertEqual(
            entries[10],
            SwipeHistoryEntry(
                tmdbID: 10,
                lastDirection: .like,
                updatedAt: Date(timeIntervalSince1970: 0),
                passCount: 0
            )
        )
        XCTAssertEqual(
            entries[20],
            SwipeHistoryEntry(
                tmdbID: 20,
                lastDirection: .like,
                updatedAt: Date(timeIntervalSince1970: 0),
                passCount: 0
            )
        )
        XCTAssertNotNil(defaults.data(forKey: "com.nurtore.movter.swipeHistory.local"))
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: TestFixtures.makeDate(year: 2030)), [10, 20])
        XCTAssertEqual(dataSource.loadSeenIDs(), [0, -5, 10, 20])
    }

    func test_LegacyMigration_PreservesExistingStructuredEntriesAndMergesUnmigratedIDs() throws {
        let existingDate = TestFixtures.makeDate(year: 2026, month: 10, day: 1)
        let existingEntry = SwipeHistoryEntry(tmdbID: 10, lastDirection: .pass, updatedAt: existingDate, passCount: 1)
        let encoded = try JSONEncoder().encode([existingEntry])
        defaults.set(encoded, forKey: "com.nurtore.movter.swipeHistory.user-A")
        defaults.set([10, 20], forKey: "com.nurtore.movter.seenFilms.user-A")

        let repo = makeRepository(userID: "user-A")
        let entries = repo.fetchHistoryEntries()

        XCTAssertEqual(entries[10], existingEntry)
        XCTAssertEqual(
            entries[20],
            SwipeHistoryEntry(
                tmdbID: 20,
                lastDirection: .like,
                updatedAt: Date(timeIntervalSince1970: 0),
                passCount: 0
            )
        )
    }

    func test_LegacyMigration_UndoRemovesEntriesWithoutResurrection() {
        defaults.set([10, 20], forKey: "com.nurtore.movter.seenFilms.local")

        let initialRepo = makeRepository()
        XCTAssertEqual(initialRepo.fetchHistoryEntries().keys.sorted(), [10, 20])

        initialRepo.removeSwipeRecord(tmdbID: 10)
        XCTAssertEqual(initialRepo.fetchHistoryEntries().keys.sorted(), [20])

        initialRepo.removeSwipeRecord(tmdbID: 20)
        XCTAssertTrue(initialRepo.fetchHistoryEntries().isEmpty)

        // Fresh data source / repository instance must not resurrect undone legacy IDs.
        let freshDataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults)
        let freshRepo = DefaultSeenFilmsRepository(localDataSource: freshDataSource)
        XCTAssertTrue(freshRepo.fetchHistoryEntries().isEmpty)
        XCTAssertTrue(freshRepo.fetchSeenIDs().isEmpty)
        XCTAssertTrue(freshDataSource.loadSeenIDs().isEmpty)
    }

    // MARK: - 14-Day Maybe Later TTL & Double-Pass Escalation

    func test_SwipeHistory_SinglePass_ExcludedBefore14DaysAndEligibleAt14Days() {
        XCTAssertEqual(DefaultSeenFilmsRepository.passCooldownInterval, 14 * 86_400)

        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)

        repo.recordSwipe(tmdbID: 42, direction: .pass, at: t0)

        let entry = repo.fetchHistoryEntries()[42]
        XCTAssertEqual(entry, SwipeHistoryEntry(tmdbID: 42, lastDirection: .pass, updatedAt: t0, passCount: 1))

        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0), [42])
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0.addingTimeInterval(14 * 86_400 - 1)), [42])
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0.addingTimeInterval(14 * 86_400)), [])
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0.addingTimeInterval(30 * 86_400)), [])
    }

    func test_SwipeHistory_DoublePass_RemainsPermanentlyExcludedAfter14Days() {
        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)
        let t1 = t0.addingTimeInterval(14 * 86_400)

        repo.recordSwipe(tmdbID: 42, direction: .pass, at: t0)
        repo.recordSwipe(tmdbID: 42, direction: .pass, at: t1)

        let entry = repo.fetchHistoryEntries()[42]
        XCTAssertEqual(entry, SwipeHistoryEntry(tmdbID: 42, lastDirection: .pass, updatedAt: t1, passCount: 2))

        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t1.addingTimeInterval(14 * 86_400)), [42])
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t1.addingTimeInterval(365 * 86_400)), [42])
    }

    func test_SwipeHistory_SinglePassThenLike_RemainsPermanentlyExcluded() {
        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)
        let t1 = t0.addingTimeInterval(14 * 86_400)

        repo.recordSwipe(tmdbID: 55, direction: .pass, at: t0)
        repo.recordSwipe(tmdbID: 55, direction: .like, at: t1)

        let entry = repo.fetchHistoryEntries()[55]
        XCTAssertEqual(entry, SwipeHistoryEntry(tmdbID: 55, lastDirection: .like, updatedAt: t1, passCount: 1))
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t1.addingTimeInterval(365 * 86_400)), [55])
    }

    func test_SwipeHistory_Like_RemainsPermanentlyExcluded() {
        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)

        repo.recordSwipe(tmdbID: 77, direction: .like, at: t0)

        let entry = repo.fetchHistoryEntries()[77]
        XCTAssertEqual(entry, SwipeHistoryEntry(tmdbID: 77, lastDirection: .like, updatedAt: t0, passCount: 0))
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0.addingTimeInterval(365 * 86_400)), [77])
    }

    func test_SwipeHistory_MarkSeen_RecordsLikeAndExcludesPermanently() {
        let repo = makeRepository()

        repo.markSeen(tmdbID: 88)

        let entry = repo.fetchHistoryEntries()[88]
        XCTAssertEqual(entry?.tmdbID, 88)
        XCTAssertEqual(entry?.lastDirection, .like)
        XCTAssertEqual(entry?.passCount, 0)
        XCTAssertTrue(repo.fetchSeenIDs().contains(88))
        XCTAssertTrue(repo.fetchExcludedIDs(asOf: Date().addingTimeInterval(365 * 86_400)).contains(88))
    }

    func test_SwipeHistory_NonPositiveIDs_AreIgnored() {
        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)

        repo.recordSwipe(tmdbID: 0, direction: .like, at: t0)
        repo.recordSwipe(tmdbID: -10, direction: .pass, at: t0)

        XCTAssertTrue(repo.fetchHistoryEntries().isEmpty)
        XCTAssertTrue(repo.fetchExcludedIDs(asOf: t0).isEmpty)
    }

    func test_SwipeHistory_RemoveSwipeRecord_RemovesOnlyTargetEntry() {
        let repo = makeRepository()
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)

        repo.recordSwipe(tmdbID: 101, direction: .like, at: t0)
        repo.recordSwipe(tmdbID: 102, direction: .pass, at: t0)
        repo.removeSwipeRecord(tmdbID: 101)

        XCTAssertNil(repo.fetchHistoryEntries()[101])
        XCTAssertNotNil(repo.fetchHistoryEntries()[102])
        XCTAssertEqual(repo.fetchExcludedIDs(asOf: t0), [102])
    }

    func test_SwipeHistory_DataSourceIsolatesEntriesByUserID() {
        let localRepo = makeRepository(userID: nil)
        let userARepo = makeRepository(userID: "user-A")
        let t0 = TestFixtures.makeDate(year: 2026, month: 6, day: 1)

        localRepo.recordSwipe(tmdbID: 1, direction: .like, at: t0)
        userARepo.recordSwipe(tmdbID: 2, direction: .pass, at: t0)

        XCTAssertEqual(localRepo.fetchHistoryEntries().keys.sorted(), [1])
        XCTAssertEqual(userARepo.fetchHistoryEntries().keys.sorted(), [2])
    }

    // MARK: - SwipeCardUseCase

    func test_SwipeCardUseCase_RecordsDirectionAndSavesWatchlistOnlyOnLike() async throws {
        let seenRepo = makeRepository()
        let watchlistRepo = MockWatchlistRepository()
        let useCase = DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo)

        let likedFilm = TestFixtures.makeMedia(id: 201, title: "Liked Film")
        let passedFilm = TestFixtures.makeMedia(id: 202, title: "Passed Film")

        try await useCase.execute(media: likedFilm, direction: .like)
        try await useCase.execute(media: passedFilm, direction: .pass)

        let entries = seenRepo.fetchHistoryEntries()
        XCTAssertEqual(entries[201]?.lastDirection, .like)
        XCTAssertEqual(entries[201]?.passCount, 0)
        XCTAssertEqual(entries[202]?.lastDirection, .pass)
        XCTAssertEqual(entries[202]?.passCount, 1)

        let watchlistItems = try await watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertEqual(watchlistItems.map(\.tmdbID), [201])
    }

    // MARK: - Pagination Cursor Store

    func test_PaginationCursorStore_DefaultsToOneAndPersistsPerUserID() {
        let localStore = makeCursorStore(userID: nil)
        let userAStore = makeCursorStore(userID: "user-A")

        XCTAssertEqual(localStore.loadPageCursor(), 1)
        XCTAssertEqual(userAStore.loadPageCursor(), 1)

        localStore.savePageCursor(7)
        userAStore.savePageCursor(42)

        XCTAssertEqual(makeCursorStore(userID: nil).loadPageCursor(), 7)
        XCTAssertEqual(makeCursorStore(userID: "user-A").loadPageCursor(), 42)
        XCTAssertEqual(defaults.integer(forKey: "com.nurtore.movter.swipePageCursor.local"), 7)
        XCTAssertEqual(defaults.integer(forKey: "com.nurtore.movter.swipePageCursor.user-A"), 42)
    }

    func test_PaginationCursorStore_ClampsOutOfRangePagesToOne() {
        let store = makeCursorStore()

        store.savePageCursor(0)
        XCTAssertEqual(store.loadPageCursor(), 1)

        store.savePageCursor(-10)
        XCTAssertEqual(store.loadPageCursor(), 1)

        store.savePageCursor(501)
        XCTAssertEqual(store.loadPageCursor(), 1)

        store.savePageCursor(500)
        XCTAssertEqual(store.loadPageCursor(), 500)

        defaults.set(999, forKey: "com.nurtore.movter.swipePageCursor.local")
        XCTAssertEqual(store.loadPageCursor(), 1)

        defaults.set(-3, forKey: "com.nurtore.movter.swipePageCursor.local")
        XCTAssertEqual(store.loadPageCursor(), 1)
    }

    // MARK: - SwipeDeckViewModel Cursor Persistence & Empty-Page Retry Cap

    func test_SwipeDeckViewModel_InitializesFromPersistedCursorAndAdvancesAcrossLaunches() async throws {
        let cursorStore = makeCursorStore()
        cursorStore.savePageCursor(3)

        let page3 = MediaPage(items: TestFixtures.makeMediaList(count: 2, startingID: 300), isLastPage: false)
        let page4 = MediaPage(items: TestFixtures.makeMediaList(count: 2, startingID: 400), isLastPage: false)

        let repo1 = MockPopularMoviesRepository(pages: [3: page3, 4: page4])
        let vm1 = await MainActor.run {
            let vm = makeViewModel(popularRepo: repo1, cursorStore: cursorStore)
            vm.start()
            return vm
        }

        try await waitUntil { vm1.queue.map(\.id) == [300, 301] }
        XCTAssertEqual(repo1.requestedPages, [3])
        XCTAssertEqual(cursorStore.loadPageCursor(), 4)

        let repo2 = MockPopularMoviesRepository(pages: [3: page3, 4: page4])
        let vm2 = await MainActor.run {
            let vm = makeViewModel(popularRepo: repo2, cursorStore: cursorStore)
            vm.start()
            return vm
        }

        try await waitUntil { vm2.queue.map(\.id) == [400, 401] }
        XCTAssertEqual(repo2.requestedPages, [4])
        XCTAssertEqual(cursorStore.loadPageCursor(), 5)
    }

    func test_SwipeDeckViewModel_WrapsCursorToOneOnLastPageAndAtMaxPage500() async throws {
        let lastPageCursorStore = MockSwipePaginationCursorStore(initialCursor: 4)
        let page4 = MediaPage(items: [TestFixtures.makeMedia(id: 40)], isLastPage: true)
        let lastPageRepo = MockPopularMoviesRepository(pages: [4: page4])

        let vmLast = await MainActor.run {
            let vm = makeViewModel(popularRepo: lastPageRepo, cursorStore: lastPageCursorStore)
            vm.start()
            return vm
        }

        try await waitUntil { vmLast.queue.map(\.id) == [40] }
        XCTAssertEqual(lastPageCursorStore.loadPageCursor(), 1)
        XCTAssertEqual(lastPageCursorStore.savedCursors, [1])

        let wrapCursorStore = MockSwipePaginationCursorStore(initialCursor: 500)
        let page500 = MediaPage(items: [], isLastPage: false)
        let page1 = MediaPage(items: [TestFixtures.makeMedia(id: 77)], isLastPage: false)
        let wrapRepo = MockPopularMoviesRepository(pages: [500: page500, 1: page1])

        let vmWrap = await MainActor.run {
            let vm = makeViewModel(popularRepo: wrapRepo, cursorStore: wrapCursorStore)
            vm.start()
            return vm
        }

        try await waitUntil { vmWrap.queue.map(\.id) == [77] }
        XCTAssertEqual(wrapRepo.requestedPages, [500, 1])
        XCTAssertEqual(wrapCursorStore.savedCursors, [1, 2])
    }

    func test_SwipeDeckViewModel_CapsConsecutiveEmptyPageRetriesAtThree() async throws {
        XCTAssertEqual(SwipeDeckViewModel.maxConsecutiveEmptyPages, 3)

        let seenRepo = MockSeenFilmsRepository(seenIDs: [1, 2, 3, 4])
        let cursorStore = MockSwipePaginationCursorStore(initialCursor: 1)
        let popularRepo = MockPopularMoviesRepository(pages: [
            1: MediaPage(items: [TestFixtures.makeMedia(id: 1), TestFixtures.makeMedia(id: 2)], isLastPage: false),
            2: MediaPage(items: [TestFixtures.makeMedia(id: 3), TestFixtures.makeMedia(id: 4)], isLastPage: false),
            3: MediaPage(items: [], isLastPage: false),
            4: MediaPage(items: [TestFixtures.makeMedia(id: 99)], isLastPage: false)
        ])

        let vm = await MainActor.run {
            let viewModel = makeViewModel(
                seenRepo: seenRepo,
                popularRepo: popularRepo,
                cursorStore: cursorStore
            )
            viewModel.start()
            return viewModel
        }

        try await waitUntil {
            popularRepo.requestedPages.count == 3 && !vm.isFetching
        }
        // Allow an extra runloop tick to verify a 4th hop is never scheduled.
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(popularRepo.requestedPages, [1, 2, 3])
        XCTAssertEqual(cursorStore.loadPageCursor(), 4)
        await MainActor.run {
            XCTAssertTrue(vm.queue.isEmpty)
            XCTAssertFalse(vm.isFetching)
            XCTAssertFalse(vm.isLastPage)
        }
    }

    func test_SwipeDeckViewModel_ResetsConsecutiveEmptyPageCounterAfterFreshPage() async throws {
        let cursorStore = MockSwipePaginationCursorStore(initialCursor: 1)
        let popularRepo = MockPopularMoviesRepository(pages: [
            1: MediaPage(items: [], isLastPage: false),
            2: MediaPage(items: [], isLastPage: false),
            3: MediaPage(items: [TestFixtures.makeMedia(id: 10)], isLastPage: false),
            4: MediaPage(items: [], isLastPage: false),
            5: MediaPage(items: [], isLastPage: false),
            6: MediaPage(items: [], isLastPage: false),
            7: MediaPage(items: [TestFixtures.makeMedia(id: 99)], isLastPage: false)
        ])

        let vm = await MainActor.run {
            let viewModel = makeViewModel(popularRepo: popularRepo, cursorStore: cursorStore)
            viewModel.start()
            return viewModel
        }

        try await waitUntil { vm.queue.map(\.id) == [10] }
        XCTAssertEqual(popularRepo.requestedPages, [1, 2, 3])

        await MainActor.run {
            vm.consumeFrontCard(direction: .pass)
        }

        try await waitUntil {
            popularRepo.requestedPages.count == 6 && !vm.isFetching
        }
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(popularRepo.requestedPages, [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(cursorStore.loadPageCursor(), 7)
    }
}
