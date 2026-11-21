import Foundation
import UIKit
import XCTest
@testable import Movter

final class Task6CardUIAndSessionLoopTests: UserDefaultsTestCase {

    // MARK: - Helpers

    @MainActor
    private func makeHarness(
        popularItems: [Media] = [],
        popularPages: [Int: MediaPage] = [:],
        isLastPage: Bool = true,
        isOnline: Bool = true,
        prefetcher: MockHeroArtworkPrefetcher? = MockHeroArtworkPrefetcher()
    ) -> (
        vc: SwipeDeckViewController,
        vm: SwipeDeckViewModel,
        seenRepo: MockSeenFilmsRepository,
        watchlistRepo: MockWatchlistRepository,
        popularRepo: MockPopularMoviesRepository,
        prefetcher: MockHeroArtworkPrefetcher?,
        coordinator: MockSwipeCoordinator,
        monitor: MockNetworkMonitor
    ) {
        let seenRepo = MockSeenFilmsRepository()
        let watchlistRepo = MockWatchlistRepository()
        let reviewsRepo = MockReviewsRepository()
        let favoritesRepo = MockTopFavoritesRepository()
        let popularRepo = MockPopularMoviesRepository(items: popularItems, isLastPage: isLastPage, pages: popularPages)
        let coordinator = MockSwipeCoordinator()
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
            buildTasteProfileUseCase: DefaultBuildUserTasteProfileUseCase(
                topFavoritesRepository: favoritesRepo,
                reviewsRepository: reviewsRepo,
                watchlistRepository: watchlistRepo,
                seenFilmsRepository: seenRepo
            ),
            monitor: monitor,
            paginationCursorStore: cursorStore,
            undoSwipeCardUseCase: DefaultUndoSwipeCardUseCase(
                seenFilmsRepository: seenRepo,
                watchlistRepository: watchlistRepo
            ),
            artworkPrefetcher: prefetcher
        )

        let vc = SwipeDeckViewController(
            viewModel: vm,
            coordinator: coordinator,
            cardViewFactory: { SwipeCardView(media: $0, loadRemoteArtwork: false) }
        )
        return (vc, vm, seenRepo, watchlistRepo, popularRepo, prefetcher, coordinator, monitor)
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

    private func makeSolidImage(color: UIColor = .red, size: CGSize = CGSize(width: 20, height: 30)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Part 6.1: Card Metadata Pills & Gradient

    @MainActor
    func test_SwipeCard_RatedMovie_DisplaysRatingGenreAndYearPills() {
        let media = TestFixtures.makeMedia(
            id: 1,
            title: "Dune: Part Two",
            releaseDate: "2024-03-15",
            voteAverage: 7.6,
            voteCount: 500,
            genreIds: [28, 12]
        )
        let card = SwipeCardView(media: media, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        card.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
        card.layoutIfNeeded()

        XCTAssertEqual(card.ratingPillText, "★ 7.6")
        XCTAssertEqual(card.genrePillText, "Action")
        XCTAssertEqual(card.yearPillText, "2024")
        XCTAssertFalse(card.isMetadataStackHidden)
    }

    @MainActor
    func test_SwipeCard_ProvisionalMovie_DisplaysFormattedScorePill() {
        let media = TestFixtures.makeMedia(
            id: 2,
            title: "Indie Hit",
            releaseDate: "2024-01-10",
            voteAverage: 8.34,
            voteCount: 5,
            genreIds: [878]
        )
        let card = SwipeCardView(media: media, loadRemoteArtwork: false, genreProvider: MockGenreProvider())

        XCTAssertEqual(card.ratingPillText, "★ 8.3")
        XCTAssertEqual(card.genrePillText, "Science Fiction")
        XCTAssertEqual(card.yearPillText, "2024")
        XCTAssertFalse(card.isMetadataStackHidden)
    }

    @MainActor
    func test_SwipeCard_UpcomingOrUnreleasedMovie_DisplaysUpcomingBadge() {
        let futureUnvoted = TestFixtures.makeMedia(
            id: 3,
            title: "Future Release",
            releaseDate: "2099-07-01",
            voteAverage: 0.0,
            voteCount: 0,
            genreIds: [12]
        )
        let futureCard = SwipeCardView(media: futureUnvoted, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        XCTAssertEqual(futureCard.ratingPillText, "Upcoming")
        XCTAssertEqual(futureCard.genrePillText, "Adventure")
        XCTAssertEqual(futureCard.yearPillText, "2099")
        XCTAssertFalse(futureCard.isMetadataStackHidden)

        let futureWithEarlyVotes = TestFixtures.makeMedia(
            id: 4,
            title: "Festival Preview",
            releaseDate: "2099-11-15",
            voteAverage: 8.1,
            voteCount: 40,
            genreIds: [18]
        )
        let festivalCard = SwipeCardView(media: futureWithEarlyVotes, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        XCTAssertEqual(festivalCard.ratingPillText, "Upcoming")

        let undatedUnvoted = TestFixtures.makeMedia(
            id: 5,
            title: "TBA Film",
            releaseDate: nil,
            voteAverage: 0.0,
            voteCount: 0,
            genreIds: nil
        )
        let tbaCard = SwipeCardView(media: undatedUnvoted, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        XCTAssertEqual(tbaCard.ratingPillText, "Upcoming")
        XCTAssertNil(tbaCard.genrePillText)
        XCTAssertNil(tbaCard.yearPillText)
        XCTAssertFalse(tbaCard.isMetadataStackHidden)
    }

    @MainActor
    func test_SwipeCard_UnratedReleasedAndMissingYear_HidesEmptyPills() {
        let unratedReleased = TestFixtures.makeMedia(
            id: 6,
            title: "Unrated Released",
            releaseDate: "2022-05-01",
            voteAverage: 0.0,
            voteCount: 0,
            genreIds: nil
        )
        let unratedCard = SwipeCardView(media: unratedReleased, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        XCTAssertNil(unratedCard.ratingPillText)
        XCTAssertNil(unratedCard.genrePillText)
        XCTAssertEqual(unratedCard.yearPillText, "2022")
        XCTAssertFalse(unratedCard.isMetadataStackHidden)

        let missingYear = TestFixtures.makeMedia(
            id: 7,
            title: "No Year Film",
            releaseDate: nil,
            voteAverage: 7.2,
            voteCount: 50,
            genreIds: nil
        )
        let missingYearCard = SwipeCardView(media: missingYear, loadRemoteArtwork: false, genreProvider: MockGenreProvider())
        XCTAssertEqual(missingYearCard.ratingPillText, "★ 7.2")
        XCTAssertNil(missingYearCard.genrePillText)
        XCTAssertNil(missingYearCard.yearPillText)
        XCTAssertFalse(missingYearCard.isMetadataStackHidden)

        let defaultProviderOfflineCard = SwipeCardView(media: unratedReleased, loadRemoteArtwork: false)
        XCTAssertNil(defaultProviderOfflineCard.genrePillText)
    }

    @MainActor
    func test_SwipeCard_GradientLocations_EqualExpectedStops() {
        let card = SwipeCardView(media: TestFixtures.makeMedia(id: 8), loadRemoteArtwork: false)
        XCTAssertEqual(card.gradientLocations, [0.0, 0.55, 1.0])
    }

    // MARK: - Part 6.2: Cross-Dissolve Poster Upgrade & Hero Artwork Prefetching

    @MainActor
    func test_SwipeCard_ApplyPosterImage_CrossDissolvesOnlyOnUpgradeWithExistingPoster() {
        let media = TestFixtures.makeMedia(id: 9, posterPath: "/poster.jpg")
        let card = SwipeCardView(media: media, loadRemoteArtwork: false)

        let initialImage = makeSolidImage(color: .blue)
        let upgradedImage = makeSolidImage(color: .green)
        let secondUpgrade = makeSolidImage(color: .orange)

        XCTAssertEqual(card.posterCrossDissolveCount, 0)

        let emptyUpgradeCard = SwipeCardView(media: media, loadRemoteArtwork: false)
        emptyUpgradeCard.applyPosterImage(upgradedImage, isUpgrade: true)
        XCTAssertEqual(emptyUpgradeCard.posterCrossDissolveCount, 0)

        card.applyPosterImage(initialImage, isUpgrade: false)
        XCTAssertEqual(card.posterCrossDissolveCount, 0)

        card.applyPosterImage(upgradedImage, isUpgrade: true)
        XCTAssertEqual(card.posterCrossDissolveCount, 1)

        card.applyPosterImage(secondUpgrade, isUpgrade: true)
        XCTAssertEqual(card.posterCrossDissolveCount, 2)
    }

    func test_ViewModel_Start_PrefetchesOnlyTop5UpcomingCardsWithoutDuplicates() async throws {
        let items = TestFixtures.makeMediaList(count: 10, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { (harness.prefetcher?.prefetchedMediaIDs.count ?? 0) == 5 }
        try await Task.sleep(for: .milliseconds(30))

        let initialPrefetched = harness.prefetcher?.prefetchedMediaIDs ?? []
        XCTAssertEqual(initialPrefetched.count, 5)
        XCTAssertEqual(Set(initialPrefetched), [1, 2, 3, 4, 5])
        XCTAssertFalse(initialPrefetched.contains(6))
        XCTAssertFalse(initialPrefetched.contains(10))

        await MainActor.run {
            harness.vm.consumeFrontCard(direction: .pass)
        }

        try await waitUntil { (harness.prefetcher?.prefetchedMediaIDs.count ?? 0) == 6 }
        try await Task.sleep(for: .milliseconds(30))

        let afterConsume = harness.prefetcher?.prefetchedMediaIDs ?? []
        XCTAssertEqual(afterConsume.count, 6)
        XCTAssertEqual(Set(afterConsume), [1, 2, 3, 4, 5, 6])
    }

    func test_ViewModel_ReconcileQueue_PrefetchesShiftedTop5WithoutDuplicates() async throws {
        let items = TestFixtures.makeMediaList(count: 10, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { (harness.prefetcher?.prefetchedMediaIDs.count ?? 0) == 5 }

        try await harness.watchlistRepo.save(TestFixtures.makeWatchlistItem(tmdbID: 1), to: .watchlist)
        await harness.vm.performQueueReconciliation()

        try await waitUntil { (harness.prefetcher?.prefetchedMediaIDs.count ?? 0) == 6 }
        let prefetched = harness.prefetcher?.prefetchedMediaIDs ?? []
        XCTAssertEqual(prefetched.count, 6)
        XCTAssertEqual(Set(prefetched), [1, 2, 3, 4, 5, 6])
    }

    // MARK: - Part 6.3: Undo Last Swipe

    func test_ViewModel_UndoLastLike_RestoresDeckRevertsProfileAndDeletesWatchlistAndHistory() async throws {
        let items = [
            TestFixtures.makeMedia(id: 1, title: "SciFi 1", releaseDate: "2024-02-01", genreIds: [878]),
            TestFixtures.makeMedia(id: 2, title: "Action 2", releaseDate: "2023-02-01", genreIds: [28]),
            TestFixtures.makeMedia(id: 3, title: "Drama 3", releaseDate: "2022-02-01", genreIds: [18]),
            TestFixtures.makeMedia(id: 4, title: "Comedy 4", releaseDate: "2021-02-01", genreIds: [35])
        ]
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            h.vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            h.vc.view.layoutIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            XCTAssertFalse(harness.vm.canUndo)
            XCTAssertFalse(harness.vc.undoButton.isEnabled)

            harness.vm.consumeFrontCard(direction: .like)

            XCTAssertTrue(harness.vm.canUndo)
            XCTAssertTrue(harness.vc.undoButton.isEnabled)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 1)
            XCTAssertEqual(harness.vm.sessionLikesCount, 1)
            XCTAssertTrue(harness.vm.excludedIDs.contains(1))
            XCTAssertEqual(harness.vm.tasteProfile.genreAffinities[878] ?? 0, 0.35, accuracy: 1e-6)
            XCTAssertEqual(harness.vm.tasteProfile.decadeAffinities[2020] ?? 0, 0.25, accuracy: 1e-6)
            XCTAssertEqual(harness.vm.tasteProfile.positiveSeedMovieIDs, [1])
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [2, 3, 4])
        }

        try await waitUntil { harness.seenRepo.fetchHistoryEntries()[1] != nil }

        await MainActor.run {
            harness.vc.undoButton.sendActions(for: .touchUpInside)

            XCTAssertFalse(harness.vm.canUndo)
            XCTAssertFalse(harness.vc.undoButton.isEnabled)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 0)
            XCTAssertEqual(harness.vm.sessionLikesCount, 0)
            XCTAssertFalse(harness.vm.excludedIDs.contains(1))
            XCTAssertEqual(harness.vm.queue.map(\.id), [1, 2, 3, 4])
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [1, 2, 3])
            XCTAssertTrue(harness.vc.cardViews[0].isUserInteractionEnabled)
            XCTAssertNotNil(harness.vc.cardViews[0].superview)
            XCTAssertEqual(harness.vm.tasteProfile.genreAffinities[878] ?? 0, 0.0, accuracy: 1e-6)
            XCTAssertEqual(harness.vm.tasteProfile.decadeAffinities[2020] ?? 0, 0.0, accuracy: 1e-6)
            XCTAssertTrue(harness.vm.tasteProfile.positiveSeedMovieIDs.isEmpty)
        }

        try await waitUntil {
            harness.seenRepo.fetchHistoryEntries()[1] == nil &&
            harness.watchlistRepo.removedWatchlistMediaIDs == [1]
        }

        let watchlistItems = try await harness.watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertTrue(watchlistItems.isEmpty)
    }

    func test_ViewModel_UndoLastPass_RestoresDeckAndSkipsWatchlistRemoval() async throws {
        let items = [
            TestFixtures.makeMedia(id: 1, title: "Liked Film", releaseDate: "2024-02-01", genreIds: [28]),
            TestFixtures.makeMedia(id: 2, title: "Passed Horror", releaseDate: "1998-02-01", genreIds: [27]),
            TestFixtures.makeMedia(id: 3, title: "Third Film", releaseDate: "2021-02-01", genreIds: [18])
        ]
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            harness.vm.consumeFrontCard(direction: .like)
            harness.vm.consumeFrontCard(direction: .pass)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 2)
            XCTAssertEqual(harness.vm.sessionLikesCount, 1)
            XCTAssertEqual(harness.vm.tasteProfile.genreAffinities[27] ?? 0, -0.15, accuracy: 1e-6)
            XCTAssertEqual(harness.vm.tasteProfile.decadeAffinities[1990] ?? 0, -0.10, accuracy: 1e-6)
        }

        try await waitUntil { harness.seenRepo.fetchHistoryEntries()[2] != nil }

        await MainActor.run {
            harness.vc.undoButton.sendActions(for: .touchUpInside)

            XCTAssertFalse(harness.vm.canUndo)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 1)
            XCTAssertEqual(harness.vm.sessionLikesCount, 1)
            XCTAssertFalse(harness.vm.excludedIDs.contains(2))
            XCTAssertTrue(harness.vm.excludedIDs.contains(1))
            XCTAssertEqual(harness.vm.queue.map(\.id), [2, 3])
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [2, 3])
            XCTAssertEqual(harness.vm.tasteProfile.genreAffinities[27] ?? 0, 0.0, accuracy: 1e-6)
            XCTAssertEqual(harness.vm.tasteProfile.decadeAffinities[1990] ?? 0, 0.0, accuracy: 1e-6)
        }

        try await waitUntil { harness.seenRepo.fetchHistoryEntries()[2] == nil }
        try await Task.sleep(for: .milliseconds(30))

        XCTAssertNotNil(harness.seenRepo.fetchHistoryEntries()[1])
        XCTAssertTrue(harness.watchlistRepo.removedWatchlistMediaIDs.isEmpty)
        let watchlistItems = try await harness.watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertEqual(watchlistItems.map(\.tmdbID), [1])
    }

    func test_ViewModel_UndoOnTenthSwipe_ExitsSessionCompleteAndRestoresTenthCard() async throws {
        let items = TestFixtures.makeMediaList(count: 12, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            for index in 0..<SwipeDeckViewModel.sessionCardLimit {
                let direction: SwipeDirection = index < 3 || index == 9 ? .like : .pass
                harness.vm.consumeFrontCard(direction: direction)
            }

            XCTAssertTrue(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 10)
            XCTAssertEqual(harness.vm.sessionLikesCount, 4)
            XCTAssertTrue(harness.vc.cardViews.isEmpty)
            XCTAssertFalse(harness.vc.sessionCompleteCard.isHidden)
            XCTAssertFalse(harness.vc.undoButton.isHidden)
            XCTAssertTrue(harness.vc.undoButton.isEnabled)
        }

        try await waitUntil { harness.seenRepo.fetchHistoryEntries()[10] != nil }

        await MainActor.run {
            harness.vc.undoButton.sendActions(for: .touchUpInside)

            XCTAssertFalse(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 9)
            XCTAssertEqual(harness.vm.sessionLikesCount, 3)
            XCTAssertFalse(harness.vm.canUndo)
            XCTAssertFalse(harness.vc.undoButton.isEnabled)
            XCTAssertTrue(harness.vc.sessionCompleteCard.isHidden)
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [10])
        }

        try await waitUntil {
            harness.seenRepo.fetchHistoryEntries()[10] == nil &&
            harness.watchlistRepo.removedWatchlistMediaIDs == [10]
        }
    }

    func test_ViewModel_UndoWhenCannotUndo_IsNoOp() async throws {
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vm.start()
            return h
        }

        try await waitUntil { harness.vm.queue.count == 3 }

        await MainActor.run {
            XCTAssertFalse(harness.vm.canUndo)
            harness.vm.undoLastSwipe()
            XCTAssertEqual(harness.vm.queue.map(\.id), [1, 2, 3])
            XCTAssertEqual(harness.vm.sessionSwipeCount, 0)
            XCTAssertEqual(harness.vm.sessionLikesCount, 0)
        }
    }

    // MARK: - Part 6.4: Interactive Session Checkpoint

    func test_SessionCheckpoint_ShowsLikesCountOpensWatchlistAndDealsNextBatch() async throws {
        let page1 = MediaPage(items: TestFixtures.makeMediaList(count: 10, startingID: 1), isLastPage: false)
        let page2 = MediaPage(items: TestFixtures.makeMediaList(count: 5, startingID: 11), isLastPage: true)

        let harness = await MainActor.run {
            let h = makeHarness(popularPages: [1: page1, 2: page2])
            h.vc.loadViewIfNeeded()
            h.vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            h.vc.view.layoutIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            for index in 0..<SwipeDeckViewModel.sessionCardLimit {
                let direction: SwipeDirection = index < 4 ? .like : .pass
                harness.vm.consumeFrontCard(direction: direction)
            }

            XCTAssertTrue(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.sessionLikesCount, 4)
            XCTAssertTrue(harness.vc.cardViews.isEmpty)
            XCTAssertFalse(harness.vc.sessionCompleteCard.isHidden)
            XCTAssertEqual(
                harness.vc.sessionCompleteBodyLabel.text,
                "You added 4 films to your Watchlist this round."
            )

            harness.vc.openWatchlistButton.sendActions(for: .touchUpInside)
            XCTAssertEqual(harness.coordinator.showWatchlistCallCount, 1)

            harness.vc.dealMoreButton.sendActions(for: .touchUpInside)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 0)
            XCTAssertEqual(harness.vm.sessionLikesCount, 0)
            XCTAssertFalse(harness.vm.isSessionComplete)
            XCTAssertFalse(harness.vm.canUndo)
            XCTAssertTrue(harness.vc.sessionCompleteCard.isHidden)
        }

        try await waitUntil {
            harness.popularRepo.requestedPages == [1, 2] &&
            harness.vc.cardViews.map(\.media.id) == [11, 12, 13]
        }
    }

    func test_SessionCheckpoint_DealMoreWithBufferedQueue_DealsNextBatchWithoutExtraFetch() async throws {
        let page1 = MediaPage(items: TestFixtures.makeMediaList(count: 15, startingID: 1), isLastPage: false)
        let harness = await MainActor.run {
            let h = makeHarness(popularPages: [1: page1])
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            for _ in 0..<SwipeDeckViewModel.sessionCardLimit {
                harness.vm.consumeFrontCard(direction: .pass)
            }
            XCTAssertTrue(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.queue.count, 5)

            harness.vc.dealMoreButton.sendActions(for: .touchUpInside)

            XCTAssertFalse(harness.vm.isSessionComplete)
            XCTAssertEqual(harness.vm.sessionSwipeCount, 0)
            XCTAssertTrue(harness.vc.sessionCompleteCard.isHidden)
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [11, 12, 13])
            XCTAssertEqual(harness.popularRepo.requestedPages, [1])
        }
    }

    // MARK: - UseCase & Factory Wiring

    func test_UndoSwipeCardUseCase_RemovesRecordAndConditionallyRemovesWatchlist() async throws {
        let dataSource = UserDefaultsSeenFilmsDataSource(defaults: defaults)
        let seenRepo = DefaultSeenFilmsRepository(localDataSource: dataSource)
        let watchlistRepo = MockWatchlistRepository()
        let swipeUseCase = DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo)
        let undoUseCase = DefaultUndoSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo)

        let liked = TestFixtures.makeMedia(id: 501, title: "Liked")
        let passed = TestFixtures.makeMedia(id: 502, title: "Passed")

        try await swipeUseCase.execute(media: liked, direction: .like)
        try await swipeUseCase.execute(media: passed, direction: .pass)

        try await undoUseCase.execute(media: passed, direction: .pass)
        XCTAssertNil(seenRepo.fetchHistoryEntries()[502])
        XCTAssertTrue(watchlistRepo.removedWatchlistMediaIDs.isEmpty)

        try await undoUseCase.execute(media: liked, direction: .like)
        XCTAssertNil(seenRepo.fetchHistoryEntries()[501])
        XCTAssertEqual(watchlistRepo.removedWatchlistMediaIDs, [501])
        let remainingWatchlist = try await watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertTrue(remainingWatchlist.isEmpty)
    }

    func test_SwipeViewFactory_WiresUndoUseCaseAndArtworkPrefetcher() async throws {
        let items = TestFixtures.makeMediaList(count: 7, startingID: 1)
        let seenRepo = MockSeenFilmsRepository()
        let watchlistRepo = MockWatchlistRepository()
        let popularRepo = MockPopularMoviesRepository(items: items, isLastPage: true)
        let prefetcher = MockHeroArtworkPrefetcher()

        let vc = await MainActor.run {
            let coordinator = MockSwipeCoordinator()
            let controller = SwipeViewFactory.makeSwipeDeck(
                coordinator: coordinator,
                watchlistRepository: watchlistRepo,
                seenFilmsRepository: seenRepo,
                popularMoviesRepository: popularRepo,
                reviewsRepository: MockReviewsRepository(),
                topFavoritesRepository: MockTopFavoritesRepository(),
                artworkPrefetcher: prefetcher,
                cardViewFactory: { SwipeCardView(media: $0, loadRemoteArtwork: false) }
            ) as! SwipeDeckViewController
            controller.loadViewIfNeeded()
            return controller
        }

        try await waitUntil {
            vc.cardViews.map(\.media.id) == [1, 2, 3] &&
            prefetcher.prefetchedMediaIDs.count == 5
        }
        XCTAssertEqual(Set(prefetcher.prefetchedMediaIDs), [1, 2, 3, 4, 5])

        await MainActor.run {
            vc.cardViews[0].performSwipe(direction: .like)
        }

        try await waitUntil {
            vc.cardViews.map(\.media.id) == [2, 3, 4] &&
            seenRepo.fetchHistoryEntries()[1] != nil
        }

        let watchlistedBeforeUndo = try await watchlistRepo.fetchAll(list: .watchlist)
        XCTAssertEqual(watchlistedBeforeUndo.map(\.tmdbID), [1])

        await MainActor.run {
            vc.undoButton.sendActions(for: .touchUpInside)
        }

        try await waitUntil {
            vc.cardViews.map(\.media.id) == [1, 2, 3] &&
            seenRepo.fetchHistoryEntries()[1] == nil &&
            watchlistRepo.removedWatchlistMediaIDs == [1]
        }
    }

    // MARK: - Reviewer Regression Fixes

    @MainActor
    func test_SwipeCard_LateStandardPoster_DoesNotOverwriteAlreadyAppliedTextlessPoster() {
        let media = TestFixtures.makeMedia(id: 90, posterPath: "/poster.jpg")
        let card = SwipeCardView(media: media, loadRemoteArtwork: false)

        let textlessImage = makeSolidImage(color: .green)
        let regularPoster = makeSolidImage(color: .blue)

        card.applyPosterImage(textlessImage, isUpgrade: true)
        XCTAssertTrue(card.hasAppliedUpgradedPoster)
        XCTAssertTrue(card.posterImage === textlessImage)

        card.applyPosterImage(regularPoster, isUpgrade: false)
        XCTAssertTrue(card.posterImage === textlessImage)
    }

    func test_SwipeDeckVC_UndoIgnoredWhileFrontCardIsCommittingAnimation() async throws {
        let items = TestFixtures.makeMediaList(count: 3, startingID: 1)
        let harness = await MainActor.run {
            let h = makeHarness(popularItems: items, isLastPage: true)
            h.vc.loadViewIfNeeded()
            h.vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            h.vc.view.layoutIfNeeded()
            return h
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [1, 2, 3] }

        await MainActor.run {
            harness.vm.consumeFrontCard(direction: .like)
            XCTAssertTrue(harness.vm.canUndo)
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [2, 3])

            // Start committing card 2 offscreen; while mid-flight, undoTapped must be ignored.
            harness.vc.cardViews[0].performSwipe(direction: .pass)
            XCTAssertTrue(harness.vc.cardViews[0].hasCommitted)
            harness.vc.undoTapped()
            XCTAssertTrue(harness.vm.canUndo)
            XCTAssertEqual(harness.vc.cardViews.map(\.media.id), [2, 3])
        }

        try await waitUntil { harness.vc.cardViews.map(\.media.id) == [3] }
        await MainActor.run {
            XCTAssertEqual(harness.vm.sessionSwipeCount, 2)
        }
    }

    func test_SwipeDeckVC_ShowsEmptyStateCardAfterThreeConsecutiveEmptyPages() async throws {
        let emptyPage = MediaPage(items: [], isLastPage: false)
        let harness = await MainActor.run {
            let h = makeHarness(popularPages: [1: emptyPage, 2: emptyPage, 3: emptyPage])
            h.vc.loadViewIfNeeded()
            return h
        }

        try await waitUntil {
            harness.popularRepo.requestedPages == [1, 2, 3] && !harness.vm.isLoading
        }

        await MainActor.run {
            XCTAssertTrue(harness.vc.cardViews.isEmpty)
            XCTAssertFalse(harness.vc.emptyStateCard.isHidden)
            XCTAssertFalse(harness.vc.loadingIndicator.isAnimating)
        }
    }

    @MainActor
    func test_SwipeDeckVC_NavigationBarKeepsCompactTitleMode() {
        let harness = makeHarness(popularItems: [], isLastPage: true)
        let nav = UINavigationController(rootViewController: harness.vc)
        nav.navigationBar.prefersLargeTitles = true
        harness.vc.loadViewIfNeeded()

        XCTAssertEqual(harness.vc.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertFalse(nav.navigationBar.prefersLargeTitles)

        nav.navigationBar.prefersLargeTitles = true
        harness.vc.beginAppearanceTransition(true, animated: false)
        harness.vc.endAppearanceTransition()
        XCTAssertFalse(nav.navigationBar.prefersLargeTitles)
    }
}

private final class MockHeroArtworkPrefetcher: HeroArtworkPrefetching, @unchecked Sendable {
    private let lock = NSLock()
    private var _prefetchedMediaIDs: [Int] = []

    var prefetchedMediaIDs: [Int] {
        lock.withLock { _prefetchedMediaIDs }
    }

    func prefetchHeroArtwork(for media: Media) async {
        lock.withLock {
            _prefetchedMediaIDs.append(media.id)
        }
    }
}
