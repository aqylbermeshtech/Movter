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
///
protocol MediaFetching: AnyObject {

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

/// `TMDBService` already declares every one of these; the conformance is the whole
/// change.
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
