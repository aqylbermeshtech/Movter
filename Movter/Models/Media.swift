//
//  Movie.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import Foundation

nonisolated struct Media: Codable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int?
    let genreIds: [Int]?

    var displayName: String {
        return title ?? name ?? "Unknown"
    }

    var mediaType: MediaType { name != nil ? .tv : .movie }

    var releaseDateString: String? { releaseDate ?? firstAirDate }

    var year: String? {
        guard let date = releaseDateString, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    var ratingState: RatingState {
        RatingState(voteAverage: voteAverage, voteCount: voteCount ?? 0, releaseDate: releaseDateString)
    }

    var fullPosterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    var largePosterURL: URL? { TMDBImageURL.url(path: posterPath, width: .wide) }

    var fullBackdropURL: URL? { TMDBImageURL.url(path: backdropPath, width: .wide) }
}
