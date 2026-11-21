//
//  PopularMoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol PopularMoviesRepository {
    func fetchPopularMovies(page: Int) async throws -> MediaPage
    func fetchDiscoverMovies(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchSimilarMovies(for movieID: Int) async throws -> [Media]
}

extension PopularMoviesRepository {
    func fetchDiscoverMovies(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        MediaPage(items: [], isLastPage: true)
    }

    func fetchSimilarMovies(for movieID: Int) async throws -> [Media] {
        []
    }
}

