//
//  DefaultPopularMoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultPopularMoviesRepository: PopularMoviesRepository {

    private let remoteDataSource: PopularMoviesRemoteDataSource

    init(remoteDataSource: PopularMoviesRemoteDataSource = DefaultPopularMoviesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        try await remoteDataSource.fetchPopularMovies(page: page)
    }
}

