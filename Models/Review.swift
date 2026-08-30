//
//  Review.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation

/// One film the user has scored and written about.
///
/// Deliberately not a `Media`: this has to render without the network, so it keeps a
/// flat snapshot. `tmdbID` and `posterPath` are nil for hand-typed entries.
nonisolated struct Review: Codable, Equatable {

    /// Whole numbers. Not `RatingState` — a personal score has no vote count and no
    /// provisional case.
    static let scoreRange = 1...10

    let id: UUID
    var filmTitle: String
    var filmYear: String?
    var tmdbID: Int?
    var posterPath: String?
    var score: Int
    var reviewText: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        filmTitle: String,
        filmYear: String? = nil,
        tmdbID: Int? = nil,
        posterPath: String? = nil,
        score: Int,
        reviewText: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.filmTitle = filmTitle
        self.filmYear = filmYear
        self.tmdbID = tmdbID
        self.posterPath = posterPath
        self.score = score.clamped(to: Self.scoreRange)
        self.reviewText = reviewText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Snapshots a catalogue title so the entry renders later without a network call.
    init(from media: Media, score: Int, reviewText: String = "") {
        self.init(
            filmTitle: media.displayName,
            filmYear: media.year,
            tmdbID: media.id,
            posterPath: media.posterPath,
            score: score,
            reviewText: reviewText
        )
    }

    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    /// "Dune  ·  2021", or just the title when the year is unknown.
    var titleWithYear: String { filmTitle.withYear(filmYear) }

    var hasReviewText: Bool {
        !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Comparable {
    nonisolated func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
