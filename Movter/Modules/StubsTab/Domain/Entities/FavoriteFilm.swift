//
//  FavoriteFilm.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation

struct FavoriteFilm: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let posterPath: String?
    let year: String?

    var posterURL: URL? {
        TMDBImageURL.url(path: posterPath, width: .poster)
    }

    init(id: Int, title: String, posterPath: String? = nil, year: String? = nil) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.year = year
    }

    init(media: Media) {
        self.init(
            id: media.id,
            title: media.displayName,
            posterPath: media.posterPath,
            year: media.year
        )
    }
}
