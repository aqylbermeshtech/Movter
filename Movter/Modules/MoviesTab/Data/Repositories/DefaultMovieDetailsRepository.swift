//
//  DefaultMovieDetailsRepository.swift
//  Movter
//

import Foundation

final class DefaultMovieDetailsRepository: MovieDetailsRepository, @unchecked Sendable {
    private let remoteDataSource: MoviesRemoteDataSource

    init(remoteDataSource: MoviesRemoteDataSource = TMDBMoviesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchTrailerKey(for mediaId: Int, type: MediaType) async throws -> String? {
        try await remoteDataSource.fetchVideo(for: mediaId, type: type)
    }

    func fetchSimilar(for mediaId: Int, type: MediaType, limit: Int) async throws -> [Media] {
        let items = try await remoteDataSource.fetchSimilar(for: mediaId, type: type)
        // TMDB occasionally recommends a title alongside itself; filter self out and limit
        return Array(items.filter { $0.id != mediaId }.prefix(limit))
    }

    func fetchCredits(for mediaId: Int, type: MediaType) async throws -> MovieCredits {
        try await remoteDataSource.fetchCredits(for: mediaId, type: type)
    }

    func fetchPrimaryGenreName(genreIds: [Int]?, type: MediaType) async -> String? {
        await remoteDataSource.fetchPrimaryGenreName(genreIds: genreIds, type: type)
    }
}

