//
//  WatchlistItem.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

struct WatchlistItem: Codable, Equatable {
    let id: UUID
    let tmdbID: Int
    var title: String
    var year: String?
    var releaseDate: String?
    var posterPath: String?
    let addedAt: Date

    init(
        id: UUID = UUID(),
        tmdbID: Int,
        title: String,
        year: String? = nil,
        releaseDate: String? = nil,
        posterPath: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.tmdbID = tmdbID
        self.title = title
        self.year = year
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.addedAt = addedAt
    }

    init(from media: Media) {
        self.init(
            tmdbID: media.id,
            title: media.displayName,
            year: media.year,
            releaseDate: media.releaseDateString,
            posterPath: media.posterPath
        )
    }

    var isUnreleased: Bool {
        let now = Date()
        if let releaseDate, let parsed = Self.isoFormatter.date(from: releaseDate) {
            return parsed > now
        }
        if let year, let releaseYear = Int(year) {
            let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
            return releaseYear > currentYear
        }
        return false
    }

    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    var titleWithYear: String { title.withYear(year) }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
