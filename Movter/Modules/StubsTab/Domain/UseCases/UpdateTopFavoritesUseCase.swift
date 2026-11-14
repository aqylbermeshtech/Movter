//
//  UpdateTopFavoritesUseCase.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation

protocol UpdateTopFavoritesUseCase {
    func add(_ film: FavoriteFilm) async -> [FavoriteFilm]
    func remove(id: Int) async -> [FavoriteFilm]
}

final class DefaultUpdateTopFavoritesUseCase: UpdateTopFavoritesUseCase {
    static let maxCount = 4

    private let repository: TopFavoritesRepository

    init(repository: TopFavoritesRepository = DefaultTopFavoritesRepository()) {
        self.repository = repository
    }

    func add(_ film: FavoriteFilm) async -> [FavoriteFilm] {
        var current = await repository.fetchTopFavorites()
        current.removeAll { $0.id == film.id }
        current.append(film)
        if current.count > Self.maxCount {
            current = Array(current.prefix(Self.maxCount))
        }
        await repository.saveTopFavorites(current)
        return current
    }

    func remove(id: Int) async -> [FavoriteFilm] {
        var current = await repository.fetchTopFavorites()
        current.removeAll { $0.id == id }
        await repository.saveTopFavorites(current)
        return current
    }
}
