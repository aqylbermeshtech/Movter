//
//  MoviesRemoteDataSource.swift
//  Movter
//

import Foundation

protocol MoviesRemoteDataSource: Sendable {
    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchVideo(for id: Int, type: MediaType) async throws -> String?
    func fetchCredits(for id: Int, type: MediaType) async throws -> MovieCredits
    func fetchSimilar(for id: Int, type: MediaType) async throws -> [Media]
    func fetchPersonDetails(for id: Int) async throws -> PersonDetails
    func fetchPersonCredits(for id: Int) async throws -> [PersonCredit]
    func fetchPrimaryGenreName(genreIds: [Int]?, type: MediaType) async -> String?
}

final class TMDBMoviesRemoteDataSource: MoviesRemoteDataSource, @unchecked Sendable {
    private let service: MediaFetching
    private let genreProvider: GenreProvider

    init(
        service: MediaFetching = TMDBService.shared,
        genreProvider: GenreProvider = GenreProvider.shared
    ) {
        self.service = service
        self.genreProvider = genreProvider
    }

    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        try await service.fetchDiscover(query: query, page: page)
    }

    func fetchVideo(for id: Int, type: MediaType) async throws -> String? {
        try await service.fetchVideo(for: id, type: type)
    }

    func fetchCredits(for id: Int, type: MediaType) async throws -> MovieCredits {
        try await service.fetchCredits(for: id, type: type)
    }

    func fetchSimilar(for id: Int, type: MediaType) async throws -> [Media] {
        try await service.fetchSimilar(for: id, type: type)
    }

    func fetchPersonDetails(for id: Int) async throws -> PersonDetails {
        try await service.fetchPersonDetails(for: id)
    }

    func fetchPersonCredits(for id: Int) async throws -> [PersonCredit] {
        try await service.fetchPersonCredits(for: id)
    }

    func fetchPrimaryGenreName(genreIds: [Int]?, type: MediaType) async -> String? {
        await withCheckedContinuation { continuation in
            genreProvider.primaryGenreName(for: genreIds, type: type) { name in
                continuation.resume(returning: name)
            }
        }
    }
}
