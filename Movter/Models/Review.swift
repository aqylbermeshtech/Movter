//
//  Review.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation

struct Review: Codable, Equatable {

    static let scoreRange = 1...10

    let id: UUID
    var filmTitle: String
    var filmYear: String?
    var tmdbID: Int?
    var posterPath: String?
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

    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    var ticketArtworkURL: URL? {
        TMDBImageURL.url(path: backdropPath, width: .wide)
            ?? TMDBImageURL.url(path: posterPath, width: .wide)
    }

    var ticketArtworkAspect: CGFloat {
        backdropPath == nil ? 3.0 / 2.0 : 9.0 / 16.0
    }

    var titleWithYear: String { filmTitle.withYear(filmYear) }

    var hasReviewText: Bool {
        !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
