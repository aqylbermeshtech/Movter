//
//  DefaultMoviesRepository.swift
//  Movter
//

import Foundation

final class DefaultMoviesRepository: MoviesRepository, @unchecked Sendable {
    private let remoteDataSource: MoviesRemoteDataSource

    init(remoteDataSource: MoviesRemoteDataSource = TMDBMoviesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchDiscover(genre: MovieGenre, page: Int) async throws -> [Media] {
        let mediaPage = try await remoteDataSource.fetchDiscover(query: genre.query, page: page)
        return mediaPage.items
    }
}

