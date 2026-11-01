//
//  SearchMoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SearchMoviesRepository {
    func searchMovies(query: String, page: Int) async throws -> MediaPage
    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchTrendingTitles(limit: Int) async throws -> [String]
}
