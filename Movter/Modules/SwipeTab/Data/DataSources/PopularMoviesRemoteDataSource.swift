//
//  PopularMoviesRemoteDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol PopularMoviesRemoteDataSource: AnyObject {
    func fetchPopularMovies(page: Int) async throws -> MediaPage
    func fetchDiscoverMovies(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchSimilarMovies(for movieID: Int) async throws -> [Media]
}

final class DefaultPopularMoviesRemoteDataSource: PopularMoviesRemoteDataSource {

    private let service: MediaFetching

    init(service: MediaFetching = TMDBService.shared) {
        self.service = service
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        try await service.fetchPopularMovies(page: page)
    }

    func fetchDiscoverMovies(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        try await service.fetchDiscover(query: query, page: page)
    }

    func fetchSimilarMovies(for movieID: Int) async throws -> [Media] {
        try await service.fetchSimilar(for: movieID, type: .movie)
    }
}

