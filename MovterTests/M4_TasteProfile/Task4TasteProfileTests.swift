import Foundation
import XCTest
@testable import Movter

final class Task4TasteProfileTests: XCTestCase {

    // MARK: - Helpers

    private func makeUseCase(
        favorites: [FavoriteFilm] = [],
        reviews: [Review] = [],
        watchlist: [WatchlistItem] = [],
        watched: [WatchlistItem] = [],
        historyEntries: [Int: SwipeHistoryEntry] = [:],
        genresByMediaID: [Int: [Int]] = [:],
        now: Date = TestFixtures.makeDate(year: 2026, month: 6, day: 15)
    ) -> (
        useCase: DefaultBuildUserTasteProfileUseCase,
        favoritesRepo: MockTopFavoritesRepository,
        reviewsRepo: MockReviewsRepository,
        watchlistRepo: MockWatchlistRepository,
        seenRepo: StubHistorySeenFilmsRepository
    ) {
        let favoritesRepo = MockTopFavoritesRepository(favorites: favorites)
        let reviewsRepo = MockReviewsRepository(reviews: reviews)
        let watchlistRepo = MockWatchlistRepository(watchlist: watchlist, watched: watched)
        let seenRepo = StubHistorySeenFilmsRepository(entries: historyEntries)

        let useCase = DefaultBuildUserTasteProfileUseCase(
            topFavoritesRepository: favoritesRepo,
            reviewsRepository: reviewsRepo,
            watchlistRepository: watchlistRepo,
            seenFilmsRepository: seenRepo,
            genreIDsForMediaID: { genresByMediaID[$0] ?? [] },
            nowProvider: { now }
        )
        return (useCase, favoritesRepo, reviewsRepo, watchlistRepo, seenRepo)
    }

    // MARK: - Cold Start

    func test_BuildProfile_WhenAllRepositoriesEmpty_ReturnsColdStartProfile() async {
        let (useCase, _, _, _, _) = makeUseCase()

        let profile = await useCase.execute()

        XCTAssertTrue(profile.isColdStart)
        XCTAssertTrue(profile.genreAffinities.isEmpty)
        XCTAssertTrue(profile.decadeAffinities.isEmpty)
        XCTAssertTrue(profile.positiveSeedMovieIDs.isEmpty)
        XCTAssertTrue(profile.previouslyPassedIDs.isEmpty)
        XCTAssertTrue(profile.topPositiveGenres(limit: 5).isEmpty)
    }

    func test_BuildProfile_WhenOnlyNeutralReviewsExist_RemainsColdStart() async {
        let reviews = [
            TestFixtures.makeReview(filmYear: "2020", tmdbID: 10, score: 5),
            TestFixtures.makeReview(filmYear: "2021", tmdbID: 11, score: 7)
        ]
        let (useCase, _, _, _, _) = makeUseCase(
            reviews: reviews,
            genresByMediaID: [10: [28], 11: [35]]
        )

        let profile = await useCase.execute()

        XCTAssertTrue(profile.isColdStart)
        XCTAssertTrue(profile.genreAffinities.isEmpty)
        XCTAssertTrue(profile.decadeAffinities.isEmpty)
        XCTAssertTrue(profile.positiveSeedMovieIDs.isEmpty)
    }

    // MARK: - Weighted Aggregation & Normalization

    func test_BuildProfile_AggregatesWeightsAcrossAllSourcesAndNormalizesIntoUnitRange() async {
        // Favorite (1): +3.0 -> genres [28, 12], decade 2020
        let favorite = TestFixtures.makeFavoriteFilm(id: 1, year: "2022")
        // High review score 8 (2): +2.5 -> genres [28], decade 2020
        let highReviewMin = TestFixtures.makeReview(filmYear: "2023", tmdbID: 2, score: 8)
        // High review score 10 (3): +2.5 -> genres [878], decade 2010
        let highReviewMax = TestFixtures.makeReview(filmYear: "2014", tmdbID: 3, score: 10)
        // Low review score 1 (4): -2.0 -> genres [27], decade 1990
        let lowReviewMin = TestFixtures.makeReview(filmYear: "1995", tmdbID: 4, score: 1)
        // Low review score 4 (5): -2.0 -> genres [27], decade 1990
        let lowReviewMax = TestFixtures.makeReview(filmYear: "1999", tmdbID: 5, score: 4)
        // Neutral reviews 5 & 7 (6, 7): 0 -> ignored
        let neutralLow = TestFixtures.makeReview(filmYear: "2001", tmdbID: 6, score: 5)
        let neutralHigh = TestFixtures.makeReview(filmYear: "2002", tmdbID: 7, score: 7)
        // Watchlist (8): +1.5 -> genres [12], decade 2010
        let watchlistItem = TestFixtures.makeWatchlistItem(tmdbID: 8, year: "2019")
        // Watched (9): +1.5 -> genres [35], decade 2000
        let watchedItem = TestFixtures.makeWatchlistItem(tmdbID: 9, year: "2005")
        // Pass history (10): -1.0 -> genres [27]
        let now = TestFixtures.makeDate(year: 2026, month: 6, day: 15)
        let passEntry = SwipeHistoryEntry(
            tmdbID: 10,
            lastDirection: .pass,
            updatedAt: now.addingTimeInterval(-3600),
            passCount: 1
        )

        let genresByID: [Int: [Int]] = [
            1: [28, 12],
            2: [28],
            3: [878],
            4: [27],
            5: [27],
            6: [18],
            7: [99],
            8: [12],
            9: [35],
            10: [27]
        ]

        // Expected raw genre scores:
        // 28: +3.0 + 2.5 = +5.5 (maxAbs = 5.5)
        // 12: +3.0 + 1.5 = +4.5
        // 878: +2.5
        // 35: +1.5
        // 27: -2.0 - 2.0 - 1.0 = -5.0
        //
        // Expected raw decade scores:
        // 2020: +3.0 + 2.5 = +5.5 (maxAbs = 5.5)
        // 2010: +2.5 + 1.5 = +4.0
        // 2000: +1.5
        // 1990: -2.0 - 2.0 = -4.0

        let (useCase, _, _, _, _) = makeUseCase(
            favorites: [favorite],
            reviews: [highReviewMin, highReviewMax, lowReviewMin, lowReviewMax, neutralLow, neutralHigh],
            watchlist: [watchlistItem],
            watched: [watchedItem],
            historyEntries: [10: passEntry],
            genresByMediaID: genresByID,
            now: now
        )

        let profile = await useCase.execute()

        XCTAssertFalse(profile.isColdStart)
        XCTAssertEqual(profile.genreAffinities[28] ?? 0, 1.0, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[12] ?? 0, 4.5 / 5.5, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[878] ?? 0, 2.5 / 5.5, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[35] ?? 0, 1.5 / 5.5, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[27] ?? 0, -5.0 / 5.5, accuracy: 1e-6)
        XCTAssertNil(profile.genreAffinities[18])
        XCTAssertNil(profile.genreAffinities[99])

        XCTAssertEqual(profile.decadeAffinities[2020] ?? 0, 1.0, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[2010] ?? 0, 4.0 / 5.5, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[2000] ?? 0, 1.5 / 5.5, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[1990] ?? 0, -4.0 / 5.5, accuracy: 1e-6)

        for score in profile.genreAffinities.values {
            XCTAssertGreaterThanOrEqual(score, -1.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }
        for score in profile.decadeAffinities.values {
            XCTAssertGreaterThanOrEqual(score, -1.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }
    }

    func test_BuildProfile_NormalizesNegativeDominantScoresAndPreservesSubUnitScores() async {
        // Negative dominant case: two low reviews (-4.0) vs one watchlist (+1.5)
        let (negativeDominantUseCase, _, _, _, _) = makeUseCase(
            reviews: [
                TestFixtures.makeReview(filmYear: "1984", tmdbID: 1, score: 2),
                TestFixtures.makeReview(filmYear: "1988", tmdbID: 2, score: 3)
            ],
            watchlist: [
                TestFixtures.makeWatchlistItem(tmdbID: 3, year: "2021")
            ],
            genresByMediaID: [1: [27], 2: [27], 3: [35]]
        )

        let negativeProfile = await negativeDominantUseCase.execute()
        XCTAssertEqual(negativeProfile.genreAffinities[27] ?? 0, -1.0, accuracy: 1e-6)
        XCTAssertEqual(negativeProfile.genreAffinities[35] ?? 0, 1.5 / 4.0, accuracy: 1e-6)
        XCTAssertEqual(negativeProfile.decadeAffinities[1980] ?? 0, -1.0, accuracy: 1e-6)
        XCTAssertEqual(negativeProfile.decadeAffinities[2020] ?? 0, 1.5 / 4.0, accuracy: 1e-6)

        // Sub-unit maxAbs case (<= 1.0): single pass penalty of -1.0 stays -1.0 without scaling
        let now = TestFixtures.makeDate(year: 2026, month: 6, day: 15)
        let (subUnitUseCase, _, _, _, _) = makeUseCase(
            historyEntries: [
                50: SwipeHistoryEntry(
                    tmdbID: 50,
                    lastDirection: .pass,
                    updatedAt: now.addingTimeInterval(-60),
                    passCount: 1
                )
            ],
            genresByMediaID: [50: [27]],
            now: now
        )

        let subUnitProfile = await subUnitUseCase.execute()
        XCTAssertFalse(subUnitProfile.isColdStart)
        XCTAssertEqual(subUnitProfile.genreAffinities[27] ?? 0, -1.0, accuracy: 1e-6)
    }

    func test_BuildProfile_ReviewWithoutTmdbID_ContributesDecadeWithoutSeedOrCrash() async {
        let (useCase, _, _, _, _) = makeUseCase(
            reviews: [
                TestFixtures.makeReview(filmYear: "1994", tmdbID: nil, score: 9),
                TestFixtures.makeReview(filmYear: "1895", tmdbID: nil, score: 10)
            ]
        )

        let profile = await useCase.execute()

        XCTAssertTrue(profile.positiveSeedMovieIDs.isEmpty)
        XCTAssertTrue(profile.genreAffinities.isEmpty)
        XCTAssertEqual(profile.decadeAffinities[1990] ?? 0, 1.0, accuracy: 1e-6)
        XCTAssertNil(profile.decadeAffinities[1890])
    }

    // MARK: - Seed ID Deduplication & Priority Order

    func test_BuildProfile_SeedsAreDeduplicatedAndOrderedByPriorityAndRecency() async {
        let favorites = [
            TestFixtures.makeFavoriteFilm(id: 101),
            TestFixtures.makeFavoriteFilm(id: 102),
            TestFixtures.makeFavoriteFilm(id: 101), // duplicate favorite
            TestFixtures.makeFavoriteFilm(id: 0)    // invalid ID skipped
        ]
        let reviews = [
            TestFixtures.makeReview(tmdbID: 102, score: 9), // duplicate of favorite -> stays at favorite rank
            TestFixtures.makeReview(tmdbID: 201, score: 8),
            TestFixtures.makeReview(tmdbID: 202, score: 10),
            TestFixtures.makeReview(tmdbID: 203, score: 4), // low review -> not a positive seed
            TestFixtures.makeReview(tmdbID: 204, score: 6), // neutral -> not a positive seed
            TestFixtures.makeReview(tmdbID: nil, score: 10) // nil -> skipped
        ]
        // 7 items across watchlist & watched; only the 5 most recent addedAt should contribute seeds.
        let watchlist = [
            TestFixtures.makeWatchlistItem(tmdbID: 301, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 1)), // 7th newest (excluded)
            TestFixtures.makeWatchlistItem(tmdbID: 302, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 3)), // 5th newest
            TestFixtures.makeWatchlistItem(tmdbID: 303, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 5)), // 3rd newest
            TestFixtures.makeWatchlistItem(tmdbID: 201, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 7))  // 1st newest (dup of high review)
        ]
        let watched = [
            TestFixtures.makeWatchlistItem(tmdbID: 304, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 2)), // 6th newest (excluded)
            TestFixtures.makeWatchlistItem(tmdbID: 305, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 4)), // 4th newest
            TestFixtures.makeWatchlistItem(tmdbID: 306, addedAt: TestFixtures.makeDate(year: 2026, month: 1, day: 6))  // 2nd newest
        ]

        let (useCase, _, _, _, _) = makeUseCase(
            favorites: favorites,
            reviews: reviews,
            watchlist: watchlist,
            watched: watched
        )

        let profile = await useCase.execute()

        // Priority: Favorites [101, 102] -> High Reviews [201, 202] -> Top 5 recent [201(dup), 306, 303, 305, 302]
        XCTAssertEqual(profile.positiveSeedMovieIDs, [101, 102, 201, 202, 306, 303, 305, 302])
        XCTAssertFalse(profile.positiveSeedMovieIDs.contains(301))
        XCTAssertFalse(profile.positiveSeedMovieIDs.contains(304))
    }

    // MARK: - Pass Cooldown Eligibility (previouslyPassedIDs)

    func test_BuildProfile_PopulatesPreviouslyPassedIDsOnlyForExpiredSinglePasses() async {
        let now = TestFixtures.makeDate(year: 2026, month: 6, day: 15)
        let cooldown = DefaultSeenFilmsRepository.passCooldownInterval // 14 days

        let history: [Int: SwipeHistoryEntry] = [
            // Exact boundary (>= 14 days), single pass -> included
            1: SwipeHistoryEntry(
                tmdbID: 1,
                lastDirection: .pass,
                updatedAt: now.addingTimeInterval(-cooldown),
                passCount: 1
            ),
            // Over 14 days, single pass -> included
            2: SwipeHistoryEntry(
                tmdbID: 2,
                lastDirection: .pass,
                updatedAt: now.addingTimeInterval(-(cooldown + 3600)),
                passCount: 1
            ),
            // Active cooldown (< 14 days), single pass -> excluded
            3: SwipeHistoryEntry(
                tmdbID: 3,
                lastDirection: .pass,
                updatedAt: now.addingTimeInterval(-(cooldown - 1)),
                passCount: 1
            ),
            // Double pass even after 14 days -> permanently excluded, NOT in previouslyPassedIDs
            4: SwipeHistoryEntry(
                tmdbID: 4,
                lastDirection: .pass,
                updatedAt: now.addingTimeInterval(-(cooldown + 86_400)),
                passCount: 2
            ),
            // Liked entry (even with prior passCount == 1 and >= 14 days) -> NOT in previouslyPassedIDs
            5: SwipeHistoryEntry(
                tmdbID: 5,
                lastDirection: .like,
                updatedAt: now.addingTimeInterval(-(cooldown + 86_400)),
                passCount: 1
            ),
            // Zero passCount -> NOT in previouslyPassedIDs
            6: SwipeHistoryEntry(
                tmdbID: 6,
                lastDirection: .pass,
                updatedAt: now.addingTimeInterval(-(cooldown + 86_400)),
                passCount: 0
            )
        ]

        let (useCase, _, _, _, _) = makeUseCase(historyEntries: history, now: now)

        let profile = await useCase.execute()

        XCTAssertEqual(profile.previouslyPassedIDs, [1, 2])
    }

    // MARK: - Intra-Session Mutations & Reverts

    func test_Profile_ApplyAndRevertSessionSwipe_UpdatesAffinitiesSeedsAndClamps() {
        var profile = UserTasteProfile(
            genreAffinities: [28: 0.85, 27: -0.95],
            decadeAffinities: [2020: 0.90, 1990: -0.95],
            positiveSeedMovieIDs: [50, 60],
            previouslyPassedIDs: [70]
        )

        let likedFilm = TestFixtures.makeMedia(
            id: 60,
            releaseDate: "2024-05-01",
            genreIds: [28, 12]
        )
        profile.applySessionSwipe(media: likedFilm, direction: .like)

        XCTAssertEqual(profile.genreAffinities[28] ?? 0, 1.0, accuracy: 1e-6)  // 0.85 + 0.35 clamped to 1.0
        XCTAssertEqual(profile.genreAffinities[12] ?? 0, 0.35, accuracy: 1e-6) // 0 + 0.35
        XCTAssertEqual(profile.decadeAffinities[2020] ?? 0, 1.0, accuracy: 1e-6) // 0.90 + 0.25 clamped to 1.0
        XCTAssertEqual(profile.positiveSeedMovieIDs, [60, 50]) // moved existing seed to front, deduplicated

        let passedFilm = TestFixtures.makeMedia(
            id: 99,
            releaseDate: "1997-07-07",
            genreIds: [27, 18]
        )
        profile.applySessionSwipe(media: passedFilm, direction: .pass)

        XCTAssertEqual(profile.genreAffinities[27] ?? 0, -1.0, accuracy: 1e-6)  // -0.95 - 0.15 clamped to -1.0
        XCTAssertEqual(profile.genreAffinities[18] ?? 0, -0.15, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[1990] ?? 0, -1.0, accuracy: 1e-6) // -0.95 - 0.10 clamped to -1.0
        XCTAssertEqual(profile.positiveSeedMovieIDs, [60, 50])

        // Revert pass
        profile.revertSessionSwipe(media: passedFilm, direction: .pass)
        XCTAssertEqual(profile.genreAffinities[27] ?? 0, -0.85, accuracy: 1e-6) // -1.0 + 0.15
        XCTAssertEqual(profile.genreAffinities[18] ?? 0, 0.0, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[1990] ?? 0, -0.90, accuracy: 1e-6)
        XCTAssertEqual(profile.positiveSeedMovieIDs, [60, 50])

        // Revert like
        profile.revertSessionSwipe(media: likedFilm, direction: .like)
        XCTAssertEqual(profile.genreAffinities[28] ?? 0, 0.65, accuracy: 1e-6) // 1.0 - 0.35
        XCTAssertEqual(profile.genreAffinities[12] ?? 0, 0.0, accuracy: 1e-6)
        XCTAssertEqual(profile.decadeAffinities[2020] ?? 0, 0.75, accuracy: 1e-6) // 1.0 - 0.25
        XCTAssertEqual(profile.positiveSeedMovieIDs, [50])
        XCTAssertEqual(profile.previouslyPassedIDs, [70])
    }

    func test_Profile_ApplyAndRevertSessionLikeFromColdStart_ReturnsToColdStartAndIgnoresInvalidIDAndPre1900Year() {
        var profile = UserTasteProfile.empty
        let media = TestFixtures.makeMedia(id: 0, releaseDate: "1898-01-01", genreIds: [35])

        profile.applySessionSwipe(media: media, direction: .like)
        XCTAssertFalse(profile.isColdStart)
        XCTAssertTrue(profile.positiveSeedMovieIDs.isEmpty)
        XCTAssertTrue(profile.decadeAffinities.isEmpty)
        XCTAssertEqual(profile.genreAffinities[35] ?? 0, 0.35, accuracy: 1e-6)

        profile.revertSessionSwipe(media: media, direction: .like)
        XCTAssertTrue(profile.isColdStart)
        XCTAssertEqual(profile.genreAffinities[35] ?? 0, 0.0, accuracy: 1e-6)
    }

    // MARK: - Top Positive Genres Sorting

    func test_Profile_TopPositiveGenres_SortsDescendingWithAscendingIDTieBreakerAndFiltersNonPositive() {
        let profile = UserTasteProfile(
            genreAffinities: [
                28: 0.6,
                12: 0.6,
                878: 0.9,
                35: 0.4,
                27: -0.8,
                18: 0.0
            ]
        )

        XCTAssertEqual(profile.topPositiveGenres(limit: 3), [878, 12, 28])
        XCTAssertEqual(profile.topPositiveGenres(limit: 10), [878, 12, 28, 35])
        XCTAssertEqual(profile.topPositiveGenres(limit: 0), [])
        XCTAssertEqual(profile.topPositiveGenres(limit: -2), [])
    }

    // MARK: - Fault Tolerance

    func test_BuildProfile_WhenReviewsAndWatchlistThrow_SurvivingRepositoriesStillContribute() async {
        let now = TestFixtures.makeDate(year: 2026, month: 6, day: 15)
        let (useCase, _, reviewsRepo, watchlistRepo, _) = makeUseCase(
            favorites: [TestFixtures.makeFavoriteFilm(id: 1, year: "2022")],
            reviews: [TestFixtures.makeReview(tmdbID: 2, score: 10)],
            watchlist: [TestFixtures.makeWatchlistItem(tmdbID: 3, year: "2020")],
            watched: [TestFixtures.makeWatchlistItem(tmdbID: 4, year: "2015")],
            historyEntries: [
                5: SwipeHistoryEntry(
                    tmdbID: 5,
                    lastDirection: .pass,
                    updatedAt: now.addingTimeInterval(-DefaultSeenFilmsRepository.passCooldownInterval),
                    passCount: 1
                )
            ],
            genresByMediaID: [1: [28], 2: [99], 3: [18], 4: [35], 5: [27]],
            now: now
        )
        reviewsRepo.fetchError = MockRepositoryError.forcedFailure
        watchlistRepo.watchlistFetchError = MockRepositoryError.forcedFailure

        let profile = await useCase.execute()

        // Favorite (+3.0, genre 28, seed 1) and Watched (+1.5, genre 35, seed 4) and SeenHistory (pass ID 5, genre 27 -1.0) survive.
        // Failing Reviews (2, genre 99) and Watchlist (3, genre 18) are safely ignored.
        XCTAssertEqual(profile.positiveSeedMovieIDs, [1, 4])
        XCTAssertEqual(profile.previouslyPassedIDs, [5])
        XCTAssertEqual(profile.genreAffinities[28] ?? 0, 1.0, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[35] ?? 0, 1.5 / 3.0, accuracy: 1e-6)
        XCTAssertEqual(profile.genreAffinities[27] ?? 0, -1.0 / 3.0, accuracy: 1e-6)
        XCTAssertNil(profile.genreAffinities[99])
        XCTAssertNil(profile.genreAffinities[18])
    }

    func test_SwipeDeckViewModel_LoadsProfileOnStartAndUpdatesIntraSessionOnConsume() async throws {
        let favorite = TestFixtures.makeFavoriteFilm(id: 500, title: "Seed Favorite", year: "2020")
        let card1 = TestFixtures.makeMedia(id: 11, title: "SciFi Hit", releaseDate: "2024-01-01", genreIds: [878, 53])
        let card2 = TestFixtures.makeMedia(id: 12, title: "Horror Pass", releaseDate: "2015-01-01", genreIds: [27])

        let favoritesRepo = MockTopFavoritesRepository(favorites: [favorite])
        let reviewsRepo = MockReviewsRepository()
        let watchlistRepo = MockWatchlistRepository()
        let seenRepo = MockSeenFilmsRepository()
        let popularRepo = MockPopularMoviesRepository(items: [card1, card2], isLastPage: true)

        let buildProfileUseCase = DefaultBuildUserTasteProfileUseCase(
            topFavoritesRepository: favoritesRepo,
            reviewsRepository: reviewsRepo,
            watchlistRepository: watchlistRepo,
            seenFilmsRepository: seenRepo,
            genreIDsForMediaID: { $0 == 500 ? [18] : [] }
        )

        let vm = await MainActor.run {
            let viewModel = SwipeDeckViewModel(
                fetchDeckUseCase: DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: popularRepo),
                swipeCardUseCase: DefaultSwipeCardUseCase(seenFilmsRepository: seenRepo, watchlistRepository: watchlistRepo),
                getExcludedIDsUseCase: DefaultGetExcludedSwipeMediaIDsUseCase(
                    seenFilmsRepository: seenRepo,
                    watchlistRepository: watchlistRepo,
                    reviewsRepository: reviewsRepo,
                    topFavoritesRepository: favoritesRepo
                ),
                buildTasteProfileUseCase: buildProfileUseCase,
                monitor: MockNetworkMonitor(isOnline: true),
                paginationCursorStore: MockSwipePaginationCursorStore()
            )
            viewModel.start()
            return viewModel
        }

        let deadline = ContinuousClock.now + .seconds(2)
        while await MainActor.run(body: { vm.queue.count < 2 }), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        await MainActor.run {
            XCTAssertEqual(vm.tasteProfile.positiveSeedMovieIDs, [500])
            XCTAssertEqual(vm.tasteProfile.genreAffinities[18] ?? 0, 1.0, accuracy: 1e-6)

            vm.consumeFrontCard(direction: .like)
            XCTAssertEqual(vm.tasteProfile.genreAffinities[878] ?? 0, 0.35, accuracy: 1e-6)
            XCTAssertEqual(vm.tasteProfile.genreAffinities[53] ?? 0, 0.35, accuracy: 1e-6)
            XCTAssertEqual(vm.tasteProfile.positiveSeedMovieIDs, [11, 500])

            vm.consumeFrontCard(direction: .pass)
            XCTAssertEqual(vm.tasteProfile.genreAffinities[27] ?? 0, -0.15, accuracy: 1e-6)
        }
    }
}

private final class StubHistorySeenFilmsRepository: SeenFilmsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [Int: SwipeHistoryEntry]

    init(entries: [Int: SwipeHistoryEntry] = [:]) {
        self.entries = entries
    }

    func fetchSeenIDs() -> Set<Int> {
        lock.withLock { fetchExcludedIDsUnlocked(asOf: Date()) }
    }

    func fetchExcludedIDs(asOf now: Date) -> Set<Int> {
        lock.withLock { fetchExcludedIDsUnlocked(asOf: now) }
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

    func fetchHistoryEntries() -> [Int: SwipeHistoryEntry] {
        lock.withLock { entries }
    }

    func markSeen(tmdbID: Int) {
        recordSwipe(tmdbID: tmdbID, direction: .like, at: Date())
    }

    func recordSwipe(tmdbID: Int, direction: SwipeDirection, at date: Date) {
        lock.withLock {
            guard tmdbID > 0 else { return }
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
    }

    func removeSwipeRecord(tmdbID: Int) {
        lock.withLock {
            _ = entries.removeValue(forKey: tmdbID)
        }
    }
}
