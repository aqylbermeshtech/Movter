//
//  TopFavoritesLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation
import MovterStorage

protocol TopFavoritesLocalDataSource {
    func load() -> [FavoriteFilm]
    func save(_ films: [FavoriteFilm])
}

final class JSONTopFavoritesLocalDataSource: TopFavoritesLocalDataSource {
    private static let filePrefix = "top-favorites"

    private let store = LocalJSONFileStore(queueLabel: "com.movter.topFavorites")

    func load() -> [FavoriteFilm] {
        (try? store.loadArray(prefix: Self.filePrefix)) ?? []
    }

    func save(_ films: [FavoriteFilm]) {
        try? store.saveArray(films, prefix: Self.filePrefix)
    }
}
