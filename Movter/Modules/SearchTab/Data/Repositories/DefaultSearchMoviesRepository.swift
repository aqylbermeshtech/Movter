//
//  DefaultSearchMoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultSearchMoviesRepository: SearchMoviesRepository {

    private let remoteDataSource: SearchRemoteDataSource

    init(remoteDataSource: SearchRemoteDataSource = DefaultSearchRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }

    func searchMovies(query: String, page: Int) async throws -> MediaPage {
        try await remoteDataSource.searchMovies(query: query, page: page)
    }

    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        try await remoteDataSource.fetchDiscover(query: query, page: page)
    }

    func fetchTrendingTitles(limit: Int) async throws -> [String] {
        let page = try await remoteDataSource.fetchTrending(page: 1)
        return page.items
            .compactMap { $0.title ?? $0.name }
            .reduce(into: [String]()) { unique, title in
                if !unique.contains(title) { unique.append(title) }
            }
            .prefix(limit)
            .map { $0 }
    }
}

