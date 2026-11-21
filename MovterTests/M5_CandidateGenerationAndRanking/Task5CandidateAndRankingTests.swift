import Foundation
import XCTest
@testable import Movter

final class Task5CandidateAndRankingTests: XCTestCase {

    // MARK: - DiscoverQuery Swipe Constructors

    func test_DiscoverQuery_SwipeTasteGenres_ConstructsExpectedPathAndParameters() {
        let query = DiscoverQuery.swipeTasteGenres([28, 878])
        let params = Dictionary(uniqueKeysWithValues: query.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(query.path, "/discover/movie")
        XCTAssertEqual(params["with_genres"], "28|878")
        XCTAssertEqual(params["vote_count.gte"], "200")
        XCTAssertEqual(params["sort_by"], "popularity.desc")
    }

    func test_DiscoverQuery_SwipeTrendingThisWeek_UsesWeeklyTrendingPath() {
        let query = DiscoverQuery.swipeTrendingThisWeek

        XCTAssertEqual(query.path, "/trending/movie/week")
        XCTAssertTrue(query.queryItems.isEmpty)
    }

    func test_DiscoverQuery_SwipeSerendipity_HandlesExcludingGenreID() {
        let excludedQuery = DiscoverQuery.swipeSerendipity(excludingGenreID: 28)
        let excludedParams = Dictionary(uniqueKeysWithValues: excludedQuery.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(excludedQuery.path, "/discover/movie")
        XCTAssertEqual(excludedParams["vote_average.gte"], "7.5")
        XCTAssertEqual(excludedParams["vote_count.gte"], "1500")
        XCTAssertEqual(excludedParams["sort_by"], "vote_average.desc")
        XCTAssertEqual(excludedParams["without_genres"], "28")

        let unfilteredQuery = DiscoverQuery.swipeSerendipity(excludingGenreID: nil)
        let unfilteredParams = Dictionary(uniqueKeysWithValues: unfilteredQuery.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(unfilteredQuery.path, "/discover/movie")
        XCTAssertEqual(unfilteredParams["vote_average.gte"], "7.5")
        XCTAssertEqual(unfilteredParams["vote_count.gte"], "1500")
        XCTAssertEqual(unfilteredParams["sort_by"], "vote_average.desc")
        XCTAssertNil(unfilteredParams["without_genres"])
    }

    // MARK: - RemoteDataSource & Repository Delegation + Backward Compatibility

    func test_PopularMoviesRepository_DelegatesDiscoverAndSimilarToRemoteDataSource() async throws {
        let service = MockMediaFetching()
        let discoverItem = TestFixtures.makeMedia(id: 501, title: "Discover Film")
        let similarItem = TestFixtures.makeMedia(id: 502, title: "Similar Film")
        service.discoverPages[2] = MediaPage(items: [discoverItem], isLastPage: false)
        service.similarByID[99] = [similarItem]

        let dataSource = DefaultPopularMoviesRemoteDataSource(service: service)
        let repository = DefaultPopularMoviesRepository(remoteDataSource: dataSource)

        let discoverPage = try await repository.fetchDiscoverMovies(query: .swipeTrendingThisWeek, page: 2)
        let similarItems = try await repository.fetchSimilarMovies(for: 99)

        XCTAssertEqual(discoverPage.items.map(\.id), [501])
        XCTAssertFalse(discoverPage.isLastPage)
        XCTAssertEqual(similarItems.map(\.id), [502])
        XCTAssertEqual(service.requestedDiscoverPaths, ["/trending/movie/week"])
        XCTAssertEqual(service.requestedSimilarIDs, [99])
    }

    func test_PopularMoviesRepository_DefaultExtensionsSupportLegacyMinimalStubs() async throws {
        let stub = MinimalPopularOnlyRepository(items: [TestFixtures.makeMedia(id: 1)])

        let popular = try await stub.fetchPopularMovies(page: 1)
        let discover = try await stub.fetchDiscoverMovies(query: .swipeTrendingThisWeek, page: 1)
        let similar = try await stub.fetchSimilarMovies(for: 42)

        XCTAssertEqual(popular.items.map(\.id), [1])
        XCTAssertTrue(discover.items.isEmpty)
        XCTAssertTrue(discover.isLastPage)
        XCTAssertTrue(similar.isEmpty)
    }

    // MARK: - Bayesian Rating & Base Score Math

    func test_BayesianRating_MatchesFormulaAtZero250AndHighVotes() {
        let zeroVotes = TestFixtures.makeMedia(id: 1, voteAverage: 9.8, voteCount: 0)
        let nilVotes = TestFixtures.makeMedia(id: 2, voteAverage: 3.0, voteCount: nil)
        let midVotes = TestFixtures.makeMedia(id: 3, voteAverage: 8.4, voteCount: 250)
        let highVotes = TestFixtures.makeMedia(id: 4, voteAverage: 8.5, voteCount: 10_000)

        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.bayesianRating(for: zeroVotes), 6.8, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.bayesianRating(for: nilVotes), 6.8, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.bayesianRating(for: midVotes), (8.4 + 6.8) / 2.0, accuracy: 1e-6)
        XCTAssertEqual(
            DefaultRankSwipeCandidatesUseCase.bayesianRating(for: highVotes),
            (10_000.0 / 10_250.0) * 8.5 + (250.0 / 10_250.0) * 6.8,
            accuracy: 1e-6
        )
    }

    func test_BayesianRanking_ProvenHighRatingBeatsLowVotePerfectTen() {
        let lowVoteTen = TestFixtures.makeMedia(id: 1, title: "Obscure Ten", voteAverage: 10.0, voteCount: 50, genreIds: [18])
        let provenHit = TestFixtures.makeMedia(id: 2, title: "Proven Hit", voteAverage: 8.8, voteCount: 2000, genreIds: [18])

        XCTAssertLessThan(
            DefaultRankSwipeCandidatesUseCase.bayesianRating(for: lowVoteTen),
            DefaultRankSwipeCandidatesUseCase.bayesianRating(for: provenHit)
        )

        let ranker = DefaultRankSwipeCandidatesUseCase()
        let ranked = ranker.execute(candidates: [lowVoteTen, provenHit], tasteProfile: .empty)

        XCTAssertEqual(ranked.map(\.id), [2, 1])
    }

    func test_BaseScore_CombinesGenreRatingDecadeAndPreviouslyPassedPenalty() {
        let profile = UserTasteProfile(
            genreAffinities: [28: 0.8, 12: 0.4],
            decadeAffinities: [2020: 0.5],
            positiveSeedMovieIDs: [1],
            previouslyPassedIDs: [99]
        )

        let regular = TestFixtures.makeMedia(
            id: 10,
            releaseDate: "2024-05-01",
            voteAverage: 8.0,
            voteCount: 250,
            genreIds: [28, 12]
        )
        let cooledDown = TestFixtures.makeMedia(
            id: 99,
            releaseDate: "2024-05-01",
            voteAverage: 8.0,
            voteCount: 250,
            genreIds: [28, 12]
        )
        let missingMetadata = TestFixtures.makeMedia(
            id: 11,
            releaseDate: nil,
            voteAverage: 6.8,
            voteCount: 0,
            genreIds: nil
        )

        // genre = (0.8 + 0.4) / 2 = 0.6; bayesian = (8.0 + 6.8)/2 = 7.4; decade = 0.5
        let expectedRegular = (0.45 * 0.6) + (0.35 * (7.4 / 10.0)) + (0.20 * 0.5)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.genreAffinity(for: regular, profile: profile), 0.6, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.decadeAffinity(for: regular, profile: profile), 0.5, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.baseScore(for: regular, profile: profile), expectedRegular, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.baseScore(for: cooledDown, profile: profile), expectedRegular - 0.10, accuracy: 1e-6)

        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.genreAffinity(for: missingMetadata, profile: profile), 0.0, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.decadeAffinity(for: missingMetadata, profile: profile), 0.0, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.baseScore(for: missingMetadata, profile: profile), 0.35 * 0.68, accuracy: 1e-6)
    }

    func test_AffinityHelpers_ClampOutOfBoundsProfileScoresToUnitRange() {
        let profile = UserTasteProfile(
            genreAffinities: [28: 2.5, 27: -3.0],
            decadeAffinities: [2020: 1.8, 1990: -2.2]
        )
        let high = TestFixtures.makeMedia(id: 1, releaseDate: "2021-01-01", genreIds: [28])
        let low = TestFixtures.makeMedia(id: 2, releaseDate: "1994-01-01", genreIds: [27])

        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.genreAffinity(for: high, profile: profile), 1.0, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.genreAffinity(for: low, profile: profile), -1.0, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.decadeAffinity(for: high, profile: profile), 1.0, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.decadeAffinity(for: low, profile: profile), -1.0, accuracy: 1e-6)
    }

    // MARK: - Anti-Clumping & Diversity Re-ordering

    func test_RankCandidates_InterleavesDramaBetweenThreeActionMovies() {
        let profile = UserTasteProfile(
            genreAffinities: [28: 0.6, 18: 0.2],
            positiveSeedMovieIDs: [999]
        )

        let action1 = TestFixtures.makeMedia(id: 1, title: "Alpha Strike", voteAverage: 8.0, voteCount: 1000, genreIds: [28])
        let action2 = TestFixtures.makeMedia(id: 2, title: "Bravo Siege", voteAverage: 7.9, voteCount: 1000, genreIds: [28])
        let action3 = TestFixtures.makeMedia(id: 3, title: "Charlie Raid", voteAverage: 7.8, voteCount: 1000, genreIds: [28])
        let drama1 = TestFixtures.makeMedia(id: 4, title: "Quiet Harbour", voteAverage: 8.0, voteCount: 1000, genreIds: [18])

        let ranker = DefaultRankSwipeCandidatesUseCase()
        let ranked = ranker.execute(candidates: [action3, drama1, action1, action2], tasteProfile: profile)

        XCTAssertEqual(ranked.map(\.id), [1, 4, 2, 3])
    }

    func test_RankCandidates_SeparatesFranchiseTitlePrefixesAndIgnoresUnrelatedShortPrefixes() {
        let dune = TestFixtures.makeMedia(id: 1, title: "Dune", voteAverage: 8.5, voteCount: 2000, genreIds: [878])
        let dune2 = TestFixtures.makeMedia(id: 2, title: "Dune: Part Two", voteAverage: 8.4, voteCount: 2000, genreIds: [12])
        let arrival = TestFixtures.makeMedia(id: 3, title: "Arrival", voteAverage: 8.0, voteCount: 2000, genreIds: [18])

        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.sameTitlePrefixPenalty(dune, dune2), 0.20, accuracy: 1e-6)
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.sameTitlePrefixPenalty(dune, arrival), 0.0, accuracy: 1e-6)

        let matrix = TestFixtures.makeMedia(id: 10, title: "The Matrix")
        let matrixReloaded = TestFixtures.makeMedia(id: 11, title: "Matrix Reloaded")
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.sameTitlePrefixPenalty(matrix, matrixReloaded), 0.20, accuracy: 1e-6)

        let her = TestFixtures.makeMedia(id: 12, title: "Her")
        let hercules = TestFixtures.makeMedia(id: 13, title: "Hercules")
        XCTAssertEqual(DefaultRankSwipeCandidatesUseCase.sameTitlePrefixPenalty(her, hercules), 0.0, accuracy: 1e-6)

        let profile = UserTasteProfile(
            genreAffinities: [878: 0.5, 12: 0.5, 18: 0.5],
            positiveSeedMovieIDs: [999]
        )
        let ranked = DefaultRankSwipeCandidatesUseCase().execute(candidates: [dune2, arrival, dune], tasteProfile: profile)

        XCTAssertEqual(ranked.map(\.id), [1, 3, 2])
    }

    func test_RankCandidates_HandlesEmptySingleAndTiedScoresDeterministically() {
        let ranker = DefaultRankSwipeCandidatesUseCase()
        XCTAssertTrue(ranker.execute(candidates: [], tasteProfile: .empty).isEmpty)

        let single = TestFixtures.makeMedia(id: 7, title: "Solo")
        XCTAssertEqual(ranker.execute(candidates: [single], tasteProfile: .empty).map(\.id), [7])

        let tieB = TestFixtures.makeMedia(id: 20, title: "Zeta", voteAverage: 7.5, voteCount: 500, genreIds: [18])
        let tieA = TestFixtures.makeMedia(id: 10, title: "Alpha", voteAverage: 7.5, voteCount: 500, genreIds: [18])
        XCTAssertEqual(ranker.execute(candidates: [tieB, tieA], tasteProfile: .empty).map(\.id), [10, 20])
    }

    // MARK: - Candidate Hygiene & Quality Floor

    func test_FilterCandidates_RemovesInvalidExcludedNoPosterLowVotesAndDuplicates_RetainsUnreleased() {
        let futureYear = Calendar(identifier: .gregorian).component(.year, from: Date()) + 2
        let futureDate = "\(futureYear)-11-15"

        let valid = TestFixtures.makeMedia(id: 1, title: "Valid", posterPath: "/a.jpg", releaseDate: "2020-05-01", voteCount: 40)
        let duplicate = TestFixtures.makeMedia(id: 1, title: "Valid Duplicate", posterPath: "/a2.jpg", releaseDate: "2020-05-01", voteCount: 900)
        let excluded = TestFixtures.makeMedia(id: 2, title: "Excluded", posterPath: "/b.jpg", releaseDate: "2020-05-01", voteCount: 500)
        let nonPositive = TestFixtures.makeMedia(id: 0, title: "Zero ID", posterPath: "/c.jpg", releaseDate: "2020-05-01", voteCount: 500)
        let negativeID = TestFixtures.makeMedia(id: -3, title: "Negative ID", posterPath: "/d.jpg", releaseDate: "2020-05-01", voteCount: 500)
        let nilPoster = TestFixtures.makeMedia(id: 3, title: "Nil Poster", posterPath: nil, releaseDate: "2020-05-01", voteCount: 500)
        let emptyPoster = TestFixtures.makeMedia(id: 4, title: "Empty Poster", posterPath: "", releaseDate: "2020-05-01", voteCount: 500)
        let whitespacePoster = TestFixtures.makeMedia(id: 5, title: "Space Poster", posterPath: "   ", releaseDate: "2020-05-01", voteCount: 500)
        let lowVoteReleased = TestFixtures.makeMedia(id: 6, title: "Low Votes", posterPath: "/e.jpg", releaseDate: "2020-05-01", voteCount: 39)
        let nilVoteReleased = TestFixtures.makeMedia(id: 7, title: "Nil Votes", posterPath: "/f.jpg", releaseDate: "2020-05-01", voteCount: nil)
        let unreleasedZeroVotes = TestFixtures.makeMedia(id: 8, title: "Upcoming Zero", posterPath: "/g.jpg", releaseDate: futureDate, voteCount: 0)
        let unreleasedNilVotes = TestFixtures.makeMedia(id: 9, title: "Upcoming Nil", posterPath: "/h.jpg", releaseDate: futureDate, voteCount: nil)

        let filtered = DefaultFetchPopularSwipeDeckUseCase.filterCandidates(
            [
                valid,
                duplicate,
                excluded,
                nonPositive,
                negativeID,
                nilPoster,
                emptyPoster,
                whitespacePoster,
                lowVoteReleased,
                nilVoteReleased,
                unreleasedZeroVotes,
                unreleasedNilVotes
            ],
            excludingIDs: [2]
        )

        XCTAssertEqual(filtered.map(\.id), [1, 8, 9])
        XCTAssertEqual(filtered.first?.title, "Valid")
    }

    // MARK: - 60 / 25 / 15 Multi-Source Blend, Seed Rotation & Pagination

    func test_PersonalizedDeck_Blends60_25_15AcrossConcurrentSourcesAndRotatesSeeds() async throws {
        let profile = UserTasteProfile(
            genreAffinities: [28: 1.0, 878: 0.8, 35: 0.1, 18: 0.1],
            decadeAffinities: [2020: 0.5],
            positiveSeedMovieIDs: [101, 102, 103, 104]
        )

        let similarSeed101 = (1...8).map {
            TestFixtures.makeMedia(id: $0, title: "SeedA \($0)", voteAverage: 7.8, voteCount: 800, genreIds: [28])
        }
        let similarSeed102 = (9...14).map {
            TestFixtures.makeMedia(id: $0, title: "SeedB \($0)", voteAverage: 7.7, voteCount: 800, genreIds: [878])
        }
        let tasteDiscoverItems = (15...22).map {
            TestFixtures.makeMedia(id: $0, title: "TasteGen \($0)", voteAverage: 7.6, voteCount: 800, genreIds: [28])
        }
        let momentumItems = (1001...1010).map {
            TestFixtures.makeMedia(id: $0, title: "Trending \($0)", voteAverage: 7.4, voteCount: 1000, genreIds: [35])
        }
        let serendipityItems = (2001...2010).map {
            TestFixtures.makeMedia(id: $0, title: "Serendipity \($0)", voteAverage: 8.2, voteCount: 2500, genreIds: [18])
        }

        let repo = MockPopularMoviesRepository()
        repo.similarByID = [
            101: similarSeed101,
            102: similarSeed102,
            103: [TestFixtures.makeMedia(id: 3001, title: "Page2 SeedC", genreIds: [28])],
            104: [TestFixtures.makeMedia(id: 3002, title: "Page2 SeedD", genreIds: [878])]
        ]
        repo.discoverQueryHandler = { query, _ in
            let paramNames = Set(query.queryItems.map(\.name))
            if query.path == "/trending/movie/week" {
                return MediaPage(items: momentumItems, isLastPage: false)
            }
            if paramNames.contains("with_genres") {
                return MediaPage(items: tasteDiscoverItems, isLastPage: false)
            }
            if paramNames.contains("without_genres") {
                return MediaPage(items: serendipityItems, isLastPage: true)
            }
            return MediaPage(items: [], isLastPage: true)
        }

        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo, targetBatchSize: 20)
        let page1Result = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: profile)

        let returnedIDs = Set(page1Result.items.map(\.id))
        let tastePoolIDs = Set((1...22))
        let momentumPoolIDs = Set((1001...1010))
        let serendipityPoolIDs = Set((2001...2010))

        XCTAssertEqual(page1Result.items.count, 20)
        XCTAssertEqual(returnedIDs.count, 20)
        XCTAssertEqual(returnedIDs.intersection(tastePoolIDs).count, 12)
        XCTAssertEqual(returnedIDs.intersection(momentumPoolIDs).count, 5)
        XCTAssertEqual(returnedIDs.intersection(serendipityPoolIDs).count, 3)
        XCTAssertFalse(page1Result.isLastPage)

        XCTAssertEqual(Set(repo.requestedSimilarIDs), [101, 102])
        XCTAssertTrue(repo.requestedDiscoverQueries.contains {
            $0.path == "/discover/movie" &&
            $0.queryItems.contains(URLQueryItem(name: "with_genres", value: "28|878")) &&
            $0.page == 1
        })
        XCTAssertTrue(repo.requestedDiscoverQueries.contains {
            $0.path == "/trending/movie/week" && $0.page == 1
        })
        XCTAssertTrue(repo.requestedDiscoverQueries.contains {
            $0.path == "/discover/movie" &&
            $0.queryItems.contains(URLQueryItem(name: "without_genres", value: "28")) &&
            $0.page == 1
        })

        // Page 2 rotates seeds deterministically to [103, 104] without repeating [101, 102]
        _ = try await useCase.execute(page: 2, excludingIDs: [], tasteProfile: profile)
        let page2SeedCalls = Array(repo.requestedSimilarIDs.dropFirst(2))
        XCTAssertEqual(Set(page2SeedCalls), [103, 104])
    }

    func test_PersonalizedDeck_DeduplicatesAcrossPoolsAndBackfillsSmallPools() async throws {
        let profile = UserTasteProfile(
            genreAffinities: [28: 1.0],
            positiveSeedMovieIDs: [101]
        )

        // Taste pool only yields 3 unique valid items (1 shared across both taste and momentum)
        let shared = TestFixtures.makeMedia(id: 50, title: "Shared Film", genreIds: [28])
        let tasteOnly = (1...2).map { TestFixtures.makeMedia(id: $0, title: "Taste \($0)", genreIds: [28]) }
        let momentumExtra = (101...118).map { TestFixtures.makeMedia(id: $0, title: "Momentum \($0)", genreIds: [35]) }
        let serendipitySmall = [TestFixtures.makeMedia(id: 201, title: "Serendipity 1", genreIds: [18])]

        let repo = MockPopularMoviesRepository()
        repo.similarByID = [101: [shared] + tasteOnly]
        repo.discoverQueryHandler = { query, _ in
            if query.path == "/trending/movie/week" {
                return MediaPage(items: [shared] + momentumExtra, isLastPage: true)
            }
            if query.queryItems.contains(where: { $0.name == "without_genres" }) {
                return MediaPage(items: serendipitySmall, isLastPage: true)
            }
            return MediaPage(items: [], isLastPage: true)
        }

        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo, targetBatchSize: 20)
        let result = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: profile)

        let ids = result.items.map(\.id)
        XCTAssertEqual(ids.count, 20)
        XCTAssertEqual(Set(ids).count, 20)
        XCTAssertTrue(ids.contains(50))
        XCTAssertTrue(ids.contains(1))
        XCTAssertTrue(ids.contains(2))
        XCTAssertTrue(ids.contains(201))
        XCTAssertTrue(result.isLastPage)
    }

    // MARK: - Cold-Start Fallback & Fault Tolerance

    func test_ColdStart_NilProfilePreservesPopularOrderAndAuthoritativeIsLastPage() async throws {
        let items = [1, 2, 3].map { TestFixtures.makeMedia(id: $0, title: "Popular \($0)") }
        let repo = MockPopularMoviesRepository(items: items, isLastPage: false)
        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo)

        let result = try await useCase.execute(page: 1, excludingIDs: [2], tasteProfile: nil)

        XCTAssertEqual(result.items.map(\.id), [1, 3])
        XCTAssertFalse(result.isLastPage)
        XCTAssertEqual(repo.requestedPages, [1])
        XCTAssertTrue(repo.requestedSimilarIDs.isEmpty)
    }

    func test_ColdStart_EmptyNonNilProfileBlendsPopularAndTrendingAndAppliesRanking() async throws {
        let popular = [
            TestFixtures.makeMedia(id: 1, title: "Lower Rated", voteAverage: 6.2, voteCount: 500, genreIds: [28]),
            TestFixtures.makeMedia(id: 2, title: "Duplicate In Trending", voteAverage: 8.9, voteCount: 1500, genreIds: [18])
        ]
        let trending = [
            TestFixtures.makeMedia(id: 2, title: "Duplicate In Trending", voteAverage: 8.9, voteCount: 1500, genreIds: [18]),
            TestFixtures.makeMedia(id: 3, title: "Top Trending", voteAverage: 9.1, voteCount: 2500, genreIds: [35])
        ]

        let repo = MockPopularMoviesRepository(items: popular, isLastPage: true)
        repo.discoverPagesByPath["/trending/movie/week"] = [1: MediaPage(items: trending, isLastPage: false)]

        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo)
        let result = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: .empty)

        XCTAssertEqual(result.items.map(\.id), [3, 2, 1])
        XCTAssertFalse(result.isLastPage)
    }

    func test_PersonalizedDeck_PartialSourceErrorStillBuildsDeckFromSurvivors() async throws {
        let profile = UserTasteProfile(
            genreAffinities: [28: 1.0],
            positiveSeedMovieIDs: [101, 102]
        )

        let repo = MockPopularMoviesRepository(
            items: [TestFixtures.makeMedia(id: 55, title: "Popular Fallback", genreIds: [35])],
            isLastPage: true
        )
        repo.discoverError = MockRepositoryError.forcedFailure
        repo.similarHandler = { movieID in
            if movieID == 101 {
                throw MockRepositoryError.forcedFailure
            }
            return [TestFixtures.makeMedia(id: 66, title: "Surviving Seed Hit", genreIds: [28])]
        }

        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo)
        let result = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: profile)

        XCTAssertEqual(Set(result.items.map(\.id)), [55, 66])
    }

    func test_FetchDeck_WhenAllSourcesFail_PropagatesError() async {
        let profile = UserTasteProfile(
            genreAffinities: [28: 1.0],
            positiveSeedMovieIDs: [101]
        )

        let repo = MockPopularMoviesRepository()
        repo.error = MockRepositoryError.forcedFailure
        repo.discoverError = MockRepositoryError.forcedFailure
        repo.similarError = MockRepositoryError.forcedFailure

        let useCase = DefaultFetchPopularSwipeDeckUseCase(popularMoviesRepository: repo)

        do {
            _ = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: profile)
            XCTFail("Expected personalized fetch to throw when all sources fail")
        } catch let error as MockRepositoryError {
            XCTAssertEqual(error, .forcedFailure)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            _ = try await useCase.execute(page: 1, excludingIDs: [], tasteProfile: nil)
            XCTFail("Expected cold-start fetch to throw when all sources fail")
        } catch let error as MockRepositoryError {
            XCTAssertEqual(error, .forcedFailure)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MinimalPopularOnlyRepository: PopularMoviesRepository {
    private let items: [Media]

    init(items: [Media]) {
        self.items = items
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        MediaPage(items: items, isLastPage: true)
    }
}
