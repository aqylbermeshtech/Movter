//
//  BuildUserTasteProfileUseCase.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

protocol BuildUserTasteProfileUseCase {
    func execute() async -> UserTasteProfile
}

final class DefaultBuildUserTasteProfileUseCase: BuildUserTasteProfileUseCase {

    private static let favoriteWeight: Double = 3.0
    private static let highReviewWeight: Double = 2.5
    private static let lowReviewWeight: Double = -2.0
    private static let watchlistWeight: Double = 1.5
    private static let passHistoryWeight: Double = -1.0
    private static let recentWatchlistSeedLimit = 5

    private let topFavoritesRepository: TopFavoritesRepository
    private let reviewsRepository: ReviewsRepository
    private let watchlistRepository: WatchlistRepository
    private let seenFilmsRepository: SeenFilmsRepository
    private let genreIDsForMediaID: @Sendable (Int) -> [Int]
    private let nowProvider: @Sendable () -> Date

    init(
        topFavoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository(),
        reviewsRepository: ReviewsRepository = DefaultReviewsRepository(),
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository(),
        seenFilmsRepository: SeenFilmsRepository = DefaultSeenFilmsRepository(),
        genreIDsForMediaID: @escaping @Sendable (Int) -> [Int] = { _ in [] },
        nowProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.topFavoritesRepository = topFavoritesRepository
        self.reviewsRepository = reviewsRepository
        self.watchlistRepository = watchlistRepository
        self.seenFilmsRepository = seenFilmsRepository
        self.genreIDsForMediaID = genreIDsForMediaID
        self.nowProvider = nowProvider
    }

    func execute() async -> UserTasteProfile {
        let favorites = await topFavoritesRepository.fetchTopFavorites()
        let reviews = (try? await reviewsRepository.fetchAll()) ?? []
        let watchlistItems = (try? await watchlistRepository.fetchAll(list: .watchlist)) ?? []
        let watchedItems = (try? await watchlistRepository.fetchAll(list: .watched)) ?? []
        let historyEntries = seenFilmsRepository.fetchHistoryEntries()
        let now = nowProvider()

        var rawGenreScores: [Int: Double] = [:]
        var rawDecadeScores: [Int: Double] = [:]
        var favoriteSeedIDs: [Int] = []
        var highReviewSeedIDs: [Int] = []

        for film in favorites {
            let genres = film.id > 0 ? genreIDsForMediaID(film.id) : []
            Self.applySignal(
                weight: Self.favoriteWeight,
                genreIDs: genres,
                yearString: film.year,
                genreScores: &rawGenreScores,
                decadeScores: &rawDecadeScores
            )
            if film.id > 0 {
                favoriteSeedIDs.append(film.id)
            }
        }

        for review in reviews {
            let weight: Double
            switch review.score {
            case 8...10:
                weight = Self.highReviewWeight
                if let tmdbID = review.tmdbID, tmdbID > 0 {
                    highReviewSeedIDs.append(tmdbID)
                }
            case 1...4:
                weight = Self.lowReviewWeight
            default:
                continue
            }
            let genres = review.tmdbID.flatMap { $0 > 0 ? genreIDsForMediaID($0) : nil } ?? []
            Self.applySignal(
                weight: weight,
                genreIDs: genres,
                yearString: review.filmYear,
                genreScores: &rawGenreScores,
                decadeScores: &rawDecadeScores
            )
        }

        let positiveListItems = watchlistItems + watchedItems
        for item in positiveListItems {
            let genres = item.tmdbID > 0 ? genreIDsForMediaID(item.tmdbID) : []
            Self.applySignal(
                weight: Self.watchlistWeight,
                genreIDs: genres,
                yearString: item.year,
                genreScores: &rawGenreScores,
                decadeScores: &rawDecadeScores
            )
        }

        let recentListSeedIDs = positiveListItems
            .filter { $0.tmdbID > 0 }
            .sorted { $0.addedAt > $1.addedAt }
            .prefix(Self.recentWatchlistSeedLimit)
            .map(\.tmdbID)

        var previouslyPassedIDs: Set<Int> = []
        for entry in historyEntries.values.sorted(by: { $0.tmdbID < $1.tmdbID }) where entry.tmdbID > 0 {
            guard entry.lastDirection == .pass else { continue }
            Self.applySignal(
                weight: Self.passHistoryWeight,
                genreIDs: genreIDsForMediaID(entry.tmdbID),
                yearString: nil,
                genreScores: &rawGenreScores,
                decadeScores: &rawDecadeScores
            )
            if entry.passCount == 1,
               now.timeIntervalSince(entry.updatedAt) >= DefaultSeenFilmsRepository.passCooldownInterval {
                previouslyPassedIDs.insert(entry.tmdbID)
            }
        }

        let positiveSeedMovieIDs = Self.deduplicatePreservingOrder(
            favoriteSeedIDs + highReviewSeedIDs + recentListSeedIDs
        )

        return UserTasteProfile(
            genreAffinities: Self.normalize(rawGenreScores),
            decadeAffinities: Self.normalize(rawDecadeScores),
            positiveSeedMovieIDs: positiveSeedMovieIDs,
            previouslyPassedIDs: previouslyPassedIDs
        )
    }

    private static func applySignal(
        weight: Double,
        genreIDs: [Int],
        yearString: String?,
        genreScores: inout [Int: Double],
        decadeScores: inout [Int: Double]
    ) {
        for genreID in genreIDs {
            genreScores[genreID, default: 0.0] += weight
        }
        if let decade = UserTasteProfile.decade(from: yearString) {
            decadeScores[decade, default: 0.0] += weight
        }
    }

    private static func normalize(_ scores: [Int: Double]) -> [Int: Double] {
        guard let maxAbs = scores.values.map({ abs($0) }).max(), maxAbs > 1.0 else {
            return scores
        }
        return scores.mapValues { $0 / maxAbs }
    }

    private static func deduplicatePreservingOrder(_ ids: [Int]) -> [Int] {
        var seen: Set<Int> = []
        var result: [Int] = []
        result.reserveCapacity(ids.count)
        for id in ids where id > 0 && seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }
}
