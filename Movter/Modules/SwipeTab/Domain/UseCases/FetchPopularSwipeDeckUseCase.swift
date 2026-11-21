//
//  FetchPopularSwipeDeckUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchPopularSwipeDeckUseCase {
    func execute(page: Int, excludingIDs: Set<Int>) async throws -> (items: [Media], isLastPage: Bool)
    func execute(page: Int, excludingIDs: Set<Int>, tasteProfile: UserTasteProfile?) async throws -> (items: [Media], isLastPage: Bool)
}

extension FetchPopularSwipeDeckUseCase {
    func execute(page: Int, excludingIDs: Set<Int>, tasteProfile: UserTasteProfile?) async throws -> (items: [Media], isLastPage: Bool) {
        try await execute(page: page, excludingIDs: excludingIDs)
    }
}

final class DefaultFetchPopularSwipeDeckUseCase: FetchPopularSwipeDeckUseCase {

    private static let minimumVoteCountFloor = 40
    private static let tasteRatio = 0.60
    private static let momentumRatio = 0.25

    private let popularMoviesRepository: PopularMoviesRepository
    private let rankCandidatesUseCase: RankSwipeCandidatesUseCase
    private let targetBatchSize: Int

    init(
        popularMoviesRepository: PopularMoviesRepository = DefaultPopularMoviesRepository(),
        rankCandidatesUseCase: RankSwipeCandidatesUseCase = DefaultRankSwipeCandidatesUseCase(),
        targetBatchSize: Int = 20
    ) {
        self.popularMoviesRepository = popularMoviesRepository
        self.rankCandidatesUseCase = rankCandidatesUseCase
        self.targetBatchSize = max(0, targetBatchSize)
    }

    func execute(page: Int, excludingIDs: Set<Int>) async throws -> (items: [Media], isLastPage: Bool) {
        try await execute(page: page, excludingIDs: excludingIDs, tasteProfile: nil)
    }

    func execute(
        page: Int,
        excludingIDs: Set<Int>,
        tasteProfile: UserTasteProfile?
    ) async throws -> (items: [Media], isLastPage: Bool) {
        if let profile = tasteProfile, !profile.isColdStart {
            return try await fetchPersonalizedDeck(page: page, excludingIDs: excludingIDs, profile: profile)
        }
        return try await fetchColdStartDeck(page: page, excludingIDs: excludingIDs, tasteProfile: tasteProfile)
    }

    // MARK: - Candidate Hygiene & Blending Helpers

    static func filterCandidates(_ candidates: [Media], excludingIDs: Set<Int>) -> [Media] {
        var seenIDs: Set<Int> = []
        var filtered: [Media] = []
        filtered.reserveCapacity(candidates.count)

        for media in candidates {
            guard media.id > 0, !excludingIDs.contains(media.id) else { continue }
            guard let posterPath = media.posterPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !posterPath.isEmpty else {
                continue
            }
            let voteCount = media.voteCount ?? 0
            if voteCount < minimumVoteCountFloor && !WatchlistItem(from: media).isUnreleased {
                continue
            }
            guard seenIDs.insert(media.id).inserted else { continue }
            filtered.append(media)
        }

        return filtered
    }

    static func rotatedSeedIDs(from seeds: [Int], page: Int, limit: Int) -> [Int] {
        guard limit > 0 else { return [] }
        var uniquePositive: [Int] = []
        var seen: Set<Int> = []
        for id in seeds where id > 0 && seen.insert(id).inserted {
            uniquePositive.append(id)
        }
        guard !uniquePositive.isEmpty else { return [] }
        let count = min(limit, uniquePositive.count)
        let normalizedPage = max(1, page)
        let startIndex = ((normalizedPage - 1) * count) % uniquePositive.count
        return (0..<count).map { offset in
            uniquePositive[(startIndex + offset) % uniquePositive.count]
        }
    }

    static func blendPools(
        taste: [Media],
        momentum: [Media],
        serendipity: [Media],
        targetBatchSize: Int
    ) -> [Media] {
        guard targetBatchSize > 0 else { return [] }

        let tasteQuota = Int((Double(targetBatchSize) * tasteRatio).rounded(.down))
        let momentumQuota = Int((Double(targetBatchSize) * momentumRatio).rounded(.down))
        let serendipityQuota = max(0, targetBatchSize - tasteQuota - momentumQuota)

        var blended: [Media] = []
        blended.reserveCapacity(targetBatchSize)
        var takenIDs: Set<Int> = []

        func append(from pool: [Media], limit: Int) -> [Media] {
            var leftovers: [Media] = []
            var added = 0
            for media in pool {
                if added < limit && takenIDs.insert(media.id).inserted {
                    blended.append(media)
                    added += 1
                } else if !takenIDs.contains(media.id) {
                    leftovers.append(media)
                }
            }
            return leftovers
        }

        let tasteLeftovers = append(from: taste, limit: tasteQuota)
        let momentumLeftovers = append(from: momentum, limit: momentumQuota)
        let serendipityLeftovers = append(from: serendipity, limit: serendipityQuota)

        if blended.count < targetBatchSize {
            let allLeftovers = tasteLeftovers + momentumLeftovers + serendipityLeftovers
            for media in allLeftovers {
                guard blended.count < targetBatchSize else { break }
                if takenIDs.insert(media.id).inserted {
                    blended.append(media)
                }
            }
        }

        return blended
    }

    // MARK: - Fetching Strategies

    private func fetchColdStartDeck(
        page: Int,
        excludingIDs: Set<Int>,
        tasteProfile: UserTasteProfile?
    ) async throws -> (items: [Media], isLastPage: Bool) {
        async let popularTask = capturePopular(page: page)
        async let trendingTask = captureDiscover(query: .swipeTrendingThisWeek, page: page)

        let (popularResult, trendingResult) = await (popularTask, trendingTask)

        let rawItems: [Media]
        let isLastPage: Bool

        switch (popularResult, trendingResult) {
        case let (.success(popularPage), .success(trendingPage)):
            if trendingPage.items.isEmpty {
                rawItems = popularPage.items
                isLastPage = popularPage.isLastPage
            } else {
                rawItems = popularPage.items + trendingPage.items
                isLastPage = popularPage.isLastPage && trendingPage.isLastPage
            }
        case let (.success(popularPage), .failure):
            rawItems = popularPage.items
            isLastPage = popularPage.isLastPage
        case let (.failure(popularError), .success(trendingPage)):
            if trendingPage.items.isEmpty {
                throw popularError
            }
            rawItems = trendingPage.items
            isLastPage = trendingPage.isLastPage
        case let (.failure(popularError), .failure):
            throw popularError
        }

        let cleaned = Self.filterCandidates(rawItems, excludingIDs: excludingIDs)
        if let tasteProfile {
            return (
                items: rankCandidatesUseCase.execute(candidates: cleaned, tasteProfile: tasteProfile),
                isLastPage: isLastPage
            )
        }
        return (items: cleaned, isLastPage: isLastPage)
    }

    private func fetchPersonalizedDeck(
        page: Int,
        excludingIDs: Set<Int>,
        profile: UserTasteProfile
    ) async throws -> (items: [Media], isLastPage: Bool) {
        let topGenres = profile.topPositiveGenres(limit: 2)
        let seedIDs = Self.rotatedSeedIDs(from: profile.positiveSeedMovieIDs, page: page, limit: 2)

        async let seed0Task = captureOptionalSimilar(movieID: seedIDs.indices.contains(0) ? seedIDs[0] : nil)
        async let seed1Task = captureOptionalSimilar(movieID: seedIDs.indices.contains(1) ? seedIDs[1] : nil)
        async let tasteDiscoverTask = captureOptionalTasteDiscover(genreIDs: topGenres, page: page)
        async let momentumTask = captureMomentum(page: page)
        async let serendipityTask = captureDiscover(
            query: .swipeSerendipity(excludingGenreID: topGenres.first),
            page: page
        )

        let (seed0Result, seed1Result, tasteDiscoverResult, momentumResult, serendipityResult) =
            await (seed0Task, seed1Task, tasteDiscoverTask, momentumTask, serendipityTask)

        var successCount = 0
        var firstError: Error?
        var pageStates: [Bool] = []

        func recordError(_ error: Error) {
            if firstError == nil {
                firstError = error
            }
        }

        var seed0Items: [Media] = []
        if let seed0Result {
            switch seed0Result {
            case let .success(items):
                successCount += 1
                seed0Items = items
            case let .failure(error):
                recordError(error)
            }
        }

        var seed1Items: [Media] = []
        if let seed1Result {
            switch seed1Result {
            case let .success(items):
                successCount += 1
                seed1Items = items
            case let .failure(error):
                recordError(error)
            }
        }

        var tasteDiscoverItems: [Media] = []
        if let tasteDiscoverResult {
            switch tasteDiscoverResult {
            case let .success(mediaPage):
                successCount += 1
                tasteDiscoverItems = mediaPage.items
                pageStates.append(mediaPage.isLastPage)
            case let .failure(error):
                recordError(error)
            }
        }

        var momentumItems: [Media] = []
        switch momentumResult {
        case let .success(mediaPage):
            successCount += 1
            momentumItems = mediaPage.items
            pageStates.append(mediaPage.isLastPage)
        case let .failure(error):
            recordError(error)
        }

        var serendipityItems: [Media] = []
        switch serendipityResult {
        case let .success(mediaPage):
            successCount += 1
            serendipityItems = mediaPage.items
            pageStates.append(mediaPage.isLastPage)
        case let .failure(error):
            recordError(error)
        }

        if successCount == 0, let firstError {
            throw firstError
        }

        let tasteInterleaved = Self.interleave([seed0Items, seed1Items, tasteDiscoverItems].filter { !$0.isEmpty })
        let cleanTaste = Self.sortPoolByBaseScore(
            Self.filterCandidates(tasteInterleaved, excludingIDs: excludingIDs),
            profile: profile
        )
        let cleanMomentum = Self.sortPoolByBaseScore(
            Self.filterCandidates(momentumItems, excludingIDs: excludingIDs),
            profile: profile
        )
        let cleanSerendipity = Self.sortPoolByBaseScore(
            Self.filterCandidates(serendipityItems, excludingIDs: excludingIDs),
            profile: profile
        )

        let blended = Self.blendPools(
            taste: cleanTaste,
            momentum: cleanMomentum,
            serendipity: cleanSerendipity,
            targetBatchSize: targetBatchSize
        )
        let ranked = rankCandidatesUseCase.execute(candidates: blended, tasteProfile: profile)
        let isLastPage = !pageStates.contains(false)
        return (items: ranked, isLastPage: isLastPage)
    }

    private func capturePopular(page: Int) async -> Result<MediaPage, Error> {
        do {
            return .success(try await popularMoviesRepository.fetchPopularMovies(page: page))
        } catch {
            return .failure(error)
        }
    }

    private func captureDiscover(query: DiscoverQuery, page: Int) async -> Result<MediaPage, Error> {
        do {
            return .success(try await popularMoviesRepository.fetchDiscoverMovies(query: query, page: page))
        } catch {
            return .failure(error)
        }
    }

    private func captureSimilar(movieID: Int) async -> Result<[Media], Error> {
        do {
            return .success(try await popularMoviesRepository.fetchSimilarMovies(for: movieID))
        } catch {
            return .failure(error)
        }
    }

    private func captureOptionalSimilar(movieID: Int?) async -> Result<[Media], Error>? {
        guard let movieID else { return nil }
        return await captureSimilar(movieID: movieID)
    }

    private func captureOptionalTasteDiscover(genreIDs: [Int], page: Int) async -> Result<MediaPage, Error>? {
        guard !genreIDs.isEmpty else { return nil }
        return await captureDiscover(query: .swipeTasteGenres(genreIDs), page: page)
    }

    private func captureMomentum(page: Int) async -> Result<MediaPage, Error> {
        do {
            let trending = try await popularMoviesRepository.fetchDiscoverMovies(
                query: .swipeTrendingThisWeek,
                page: page
            )
            if !trending.items.isEmpty {
                return .success(trending)
            }
            let popular = try await popularMoviesRepository.fetchPopularMovies(page: page)
            return .success(MediaPage(items: popular.items, isLastPage: trending.isLastPage && popular.isLastPage))
        } catch {
            do {
                let popular = try await popularMoviesRepository.fetchPopularMovies(page: page)
                return .success(popular)
            } catch let popularError {
                return .failure(popularError)
            }
        }
    }

    private static func interleave(_ arrays: [[Media]]) -> [Media] {
        guard !arrays.isEmpty else { return [] }
        let maxCount = arrays.map(\.count).max() ?? 0
        var result: [Media] = []
        result.reserveCapacity(arrays.reduce(0) { $0 + $1.count })
        for index in 0..<maxCount {
            for array in arrays where index < array.count {
                result.append(array[index])
            }
        }
        return result
    }

    private static func sortPoolByBaseScore(_ pool: [Media], profile: UserTasteProfile) -> [Media] {
        pool
            .map { (media: $0, score: DefaultRankSwipeCandidatesUseCase.baseScore(for: $0, profile: profile)) }
            .sorted { $0.score > $1.score }
            .map(\.media)
    }
}

