//
//  DefaultTopFavoritesRepository.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation

final class DefaultTopFavoritesRepository: TopFavoritesRepository {
    private let localDataSource: TopFavoritesLocalDataSource

    init(localDataSource: TopFavoritesLocalDataSource = JSONTopFavoritesLocalDataSource()) {
        self.localDataSource = localDataSource
    }

    func fetchTopFavorites() async -> [FavoriteFilm] {
        localDataSource.load()
    }

    func saveTopFavorites(_ films: [FavoriteFilm]) async {
        localDataSource.save(films)
    }
}
