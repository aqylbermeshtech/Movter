//
//  WatchlistItem.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

nonisolated struct WatchlistItem: Codable, Equatable {
    let id: UUID
    let tmdbID: Int
    var title: String
    var year: String?
    var posterPath: String?
    let addedAt: Date

    init(
        id: UUID = UUID(),
        tmdbID: Int,
        title: String,
        year: String? = nil,
        posterPath: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.tmdbID = tmdbID
        self.title = title
        self.year = year
        self.posterPath = posterPath
        self.addedAt = addedAt
    }

    init(from media: Media) {
        self.init(tmdbID: media.id, title: media.displayName, year: media.year, posterPath: media.posterPath)
    }

    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    var titleWithYear: String { title.withYear(year) }
}
