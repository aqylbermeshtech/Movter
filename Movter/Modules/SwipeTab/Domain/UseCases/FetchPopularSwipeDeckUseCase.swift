//
//  FetchPopularSwipeDeckUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchPopularSwipeDeckUseCase {
    func execute(page: Int, excludingIDs: Set<Int>) async throws -> (items: [Media], isLastPage: Bool)
}

final class DefaultFetchPopularSwipeDeckUseCase: FetchPopularSwipeDeckUseCase {

    private let popularMoviesRepository: PopularMoviesRepository

    init(popularMoviesRepository: PopularMoviesRepository = DefaultPopularMoviesRepository()) {
        self.popularMoviesRepository = popularMoviesRepository
    }

    func execute(page: Int, excludingIDs: Set<Int>) async throws -> (items: [Media], isLastPage: Bool) {
        let mediaPage = try await popularMoviesRepository.fetchPopularMovies(page: page)
        let filtered = mediaPage.items.filter { !excludingIDs.contains($0.id) }
        return (items: filtered, isLastPage: mediaPage.isLastPage)
    }
}

