//
//  TopFavoritesRepository.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Foundation

protocol TopFavoritesRepository {
    func fetchTopFavorites() async -> [FavoriteFilm]
    func saveTopFavorites(_ films: [FavoriteFilm]) async
}
