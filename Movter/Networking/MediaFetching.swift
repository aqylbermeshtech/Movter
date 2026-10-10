//
//  MediaFetching.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// The catalogue endpoints the app actually calls.
///
/// Exists so view models can be handed a stub instead of reaching for
/// `TMDBService.shared` — the same seam `ReviewStoring` and `WatchlistStoring`
/// already provide for storage. Deliberately narrower than `TMDBService`: it lists
/// what callers use, not everything the service can do.
protocol MediaFetching: AnyObject {

    // MARK: - Modern Async APIs

    func fetchVideo(for id: Int, type: MediaType) async throws -> String?
    func fetchCredits(for id: Int, type: MediaType) async throws -> MovieCredits
    func fetchSimilar(for id: Int, type: MediaType) async throws -> [Media]
    func fetchGenres(type: MediaType) async throws -> [GenreListResponse.Genre]
    func fetchPersonDetails(for id: Int) async throws -> PersonDetails
    func fetchPersonCredits(for id: Int) async throws -> [PersonCredit]
    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchPopularMovies(page: Int) async throws -> MediaPage
    func searchMovies(query: String, page: Int) async throws -> MediaPage

    // MARK: - Backward-Compatible Closure APIs

    func fetchVideo(
        for id: Int, type: MediaType,
        completion: @escaping (String?) -> Void
    )

    func fetchCredits(
        for id: Int, type: MediaType,
        completion: @escaping (MovieCredits?) -> Void
    )

    func fetchSimilar(
        for id: Int, type: MediaType,
        completion: @escaping ([Media]?) -> Void
    )

    func fetchGenres(
        type: MediaType,
        completion: @escaping ([GenreListResponse.Genre]?) -> Void
    )

    func fetchPersonDetails(
        for id: Int,
        completion: @escaping (PersonDetails?) -> Void
    )

    func fetchPersonCredits(
        for id: Int,
        completion: @escaping ([PersonCredit]) -> Void
    )

    func fetchDiscover(
        query: DiscoverQuery, page: Int,
        completion: @escaping (MediaPage?) -> Void
    )

    func fetchPopularMovies(
        page: Int,
        completion: @escaping (MediaPage?) -> Void
    )

    func searchMovies(
        query: String, page: Int,
        completion: @escaping (MediaPage?) -> Void
    )
}

// MARK: - Default Protocol Bridging

extension MediaFetching {

    func fetchVideo(
        for id: Int, type: MediaType,
        completion: @escaping (String?) -> Void
    ) {
        Task {
            let result = try? await fetchVideo(for: id, type: type)
            await MainActor.run { completion(result) }
        }
    }

    func fetchCredits(
        for id: Int, type: MediaType,
        completion: @escaping (MovieCredits?) -> Void
    ) {
        Task {
            let result = try? await fetchCredits(for: id, type: type)
            await MainActor.run { completion(result) }
        }
    }

    func fetchSimilar(
        for id: Int, type: MediaType,
        completion: @escaping ([Media]?) -> Void
    ) {
        Task {
            let result = try? await fetchSimilar(for: id, type: type)
            await MainActor.run { completion(result) }
        }
    }

    func fetchGenres(
        type: MediaType,
        completion: @escaping ([GenreListResponse.Genre]?) -> Void
    ) {
        Task {
            let result = try? await fetchGenres(type: type)
            await MainActor.run { completion(result) }
        }
    }

    func fetchPersonDetails(
        for id: Int,
        completion: @escaping (PersonDetails?) -> Void
    ) {
        Task {
            let result = try? await fetchPersonDetails(for: id)
            await MainActor.run { completion(result) }
        }
    }

    func fetchPersonCredits(
        for id: Int,
        completion: @escaping ([PersonCredit]) -> Void
    ) {
        Task {
            let result = (try? await fetchPersonCredits(for: id)) ?? []
            await MainActor.run { completion(result) }
        }
    }

    func fetchDiscover(
        query: DiscoverQuery, page: Int,
        completion: @escaping (MediaPage?) -> Void
    ) {
        Task {
            let result = try? await fetchDiscover(query: query, page: page)
            await MainActor.run { completion(result) }
        }
    }

    func fetchPopularMovies(
        page: Int,
        completion: @escaping (MediaPage?) -> Void
    ) {
        Task {
            let result = try? await fetchPopularMovies(page: page)
            await MainActor.run { completion(result) }
        }
    }

    func searchMovies(
        query: String, page: Int,
        completion: @escaping (MediaPage?) -> Void
    ) {
        Task {
            let result = try? await searchMovies(query: query, page: page)
            await MainActor.run { completion(result) }
        }
    }
}

/// `TMDBService` declares both modern async and completion APIs.
extension TMDBService: MediaFetching {}

/// Genre-name lookup, kept separate from `MediaFetching` because `GenreProvider` adds
/// caching and request coalescing on top of the raw endpoint.
protocol GenreProviding: AnyObject {
    func primaryGenreName(
        for ids: [Int]?, type: MediaType,
        completion: @escaping (String?) -> Void
    )
}

extension GenreProvider: GenreProviding {}
