//
//  DefaultFilmSearchRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultFilmSearchRepository: FilmSearchRepository {

    private let service: MediaFetching

    init(service: MediaFetching = TMDBService.shared) {
        self.service = service
    }

    func searchFilms(query: String, page: Int = 1) async throws -> [Media] {
        let mediaPage = try await service.searchMovies(query: query, page: page)
        return mediaPage.items
    }
}

