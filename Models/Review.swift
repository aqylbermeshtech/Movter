//
//  Review.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation

nonisolated struct Review: Codable, Equatable {

    static let scoreRange = 1...10

    let id: UUID
    var filmTitle: String
    var filmYear: String?
    var tmdbID: Int?
    var posterPath: String?
    /// TMDB's 16:9 still. Optional and decoded as nil for reviews written before it was
    /// captured, which is why every use of it falls back to the poster.
    var backdropPath: String?
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
        backdropPath: String? = nil,
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
        self.backdropPath = backdropPath
        self.score = score.clamped(to: Self.scoreRange)
        self.reviewText = reviewText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from media: Media, score: Int, reviewText: String = "") {
        self.init(
            filmTitle: media.displayName,
            filmYear: media.year,
            tmdbID: media.id,
            posterPath: media.posterPath,
            backdropPath: media.backdropPath,
            score: score,
            reviewText: reviewText
        )
    }

    /// Thumbnail width, for the list rows and pickers that show it small.
    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    /// Full-bleed artwork for the ticket. The backdrop first: it is a still, which is
    /// the shape the stub wants, and it needs no cropping to sit there. The poster is
    /// the fallback for older reviews and for titles TMDB has no still for. Both at
    /// `.wide`, since this is rendered near the full width of the screen.
    var ticketArtworkURL: URL? {
        TMDBImageURL.url(path: backdropPath, width: .wide)
            ?? TMDBImageURL.url(path: posterPath, width: .wide)
    }

    /// The shape of whatever `ticketArtworkURL` resolved to, as height over width — so
    /// the ticket can give a still the band it needs and a poster the room it needs.
    var ticketArtworkAspect: CGFloat {
        backdropPath == nil ? 3.0 / 2.0 : 9.0 / 16.0
    }

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
