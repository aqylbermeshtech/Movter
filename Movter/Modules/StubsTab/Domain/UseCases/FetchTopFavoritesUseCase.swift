//
//  FetchTopFavoritesUseCase.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation

protocol FetchTopFavoritesUseCase {
    func execute() async -> [FavoriteFilm]
}

final class DefaultFetchTopFavoritesUseCase: FetchTopFavoritesUseCase {
    private let repository: TopFavoritesRepository

    init(repository: TopFavoritesRepository = DefaultTopFavoritesRepository()) {
        self.repository = repository
    }

    func execute() async -> [FavoriteFilm] {
        await repository.fetchTopFavorites()
    }
}
