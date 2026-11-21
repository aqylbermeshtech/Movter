//
//  UserTasteProfile.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

nonisolated struct UserTasteProfile: Equatable, Sendable {
    /// Normalized affinity score per TMDB Genre ID (range: -1.0 ... +1.0)
    var genreAffinities: [Int: Double]
    /// Preferred decade weights (e.g., 2020: 0.8, 2010: 0.5), range: -1.0 ... +1.0
    var decadeAffinities: [Int: Double]
    /// Top positive seed TMDB IDs for /recommendations queries (deduplicated, priority ordered)
    var positiveSeedMovieIDs: [Int]
    /// IDs that were passed once and re-entered eligibility after the 14-day cooldown
    var previouslyPassedIDs: Set<Int>

    private static let affinityRange: ClosedRange<Double> = -1.0...1.0
    private static let sessionLikeGenreDelta: Double = 0.35
    private static let sessionLikeDecadeDelta: Double = 0.25
    private static let sessionPassGenreDelta: Double = -0.15
    private static let sessionPassDecadeDelta: Double = -0.10

    static let empty = UserTasteProfile()

    init(
        genreAffinities: [Int: Double] = [:],
        decadeAffinities: [Int: Double] = [:],
        positiveSeedMovieIDs: [Int] = [],
        previouslyPassedIDs: Set<Int> = []
    ) {
        self.genreAffinities = genreAffinities
        self.decadeAffinities = decadeAffinities
        self.positiveSeedMovieIDs = positiveSeedMovieIDs
        self.previouslyPassedIDs = previouslyPassedIDs
    }

    var isColdStart: Bool {
        positiveSeedMovieIDs.isEmpty && genreAffinities.values.allSatisfy { abs($0) < 1e-6 }
    }

    /// Updates intra-session affinities and seed IDs immediately after a card swipe.
    mutating func applySessionSwipe(media: Media, direction: SwipeDirection) {
        switch direction {
        case .like:
            adjustAffinities(
                for: media,
                genreDelta: Self.sessionLikeGenreDelta,
                decadeDelta: Self.sessionLikeDecadeDelta
            )
            if media.id > 0 {
                positiveSeedMovieIDs.removeAll { $0 == media.id }
                positiveSeedMovieIDs.insert(media.id, at: 0)
            }
        case .pass:
            adjustAffinities(
                for: media,
                genreDelta: Self.sessionPassGenreDelta,
                decadeDelta: Self.sessionPassDecadeDelta
            )
        }
    }

    /// Reverses a previous `applySessionSwipe(media:direction:)` update (e.g., on undo or persistence rollback).
    mutating func revertSessionSwipe(media: Media, direction: SwipeDirection) {
        switch direction {
        case .like:
            adjustAffinities(
                for: media,
                genreDelta: -Self.sessionLikeGenreDelta,
                decadeDelta: -Self.sessionLikeDecadeDelta
            )
            positiveSeedMovieIDs.removeAll { $0 == media.id }
        case .pass:
            adjustAffinities(
                for: media,
                genreDelta: -Self.sessionPassGenreDelta,
                decadeDelta: -Self.sessionPassDecadeDelta
            )
        }
    }

    /// Returns up to `limit` positive genre IDs ordered by descending affinity, then ascending genre ID.
    func topPositiveGenres(limit: Int) -> [Int] {
        guard limit > 0 else { return [] }
        return genreAffinities
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return lhs.key < rhs.key
            }
            .prefix(limit)
            .map(\.key)
    }

    /// Extracts a decade bucket (e.g., `2020`) from a 4-digit year or ISO date prefix (`>= 1900`).
    static func decade(from yearString: String?) -> Int? {
        guard let trimmed = yearString?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmed.count >= 4 else {
            return nil
        }
        let yearCandidate: String
        if trimmed.count == 4 {
            yearCandidate = trimmed
        } else {
            let fifthIndex = trimmed.index(trimmed.startIndex, offsetBy: 4)
            guard trimmed[fifthIndex] == "-" else { return nil }
            yearCandidate = String(trimmed.prefix(4))
        }
        guard let year = Int(yearCandidate), year >= 1900 else {
            return nil
        }
        return (year / 10) * 10
    }

    private mutating func adjustAffinities(for media: Media, genreDelta: Double, decadeDelta: Double) {
        for genreID in media.genreIds ?? [] {
            let current = genreAffinities[genreID] ?? 0.0
            genreAffinities[genreID] = Self.clampAffinity(current + genreDelta)
        }
        if let decade = Self.decade(from: media.year) {
            let current = decadeAffinities[decade] ?? 0.0
            decadeAffinities[decade] = Self.clampAffinity(current + decadeDelta)
        }
    }

    private static func clampAffinity(_ value: Double) -> Double {
        min(affinityRange.upperBound, max(affinityRange.lowerBound, value))
    }
}
