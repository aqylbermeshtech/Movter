//
//  FetchTrendingTitlesUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchTrendingTitlesUseCase {
    func execute(limit: Int) async throws -> [String]
}

final class DefaultFetchTrendingTitlesUseCase: FetchTrendingTitlesUseCase {
    private let repository: SearchMoviesRepository
    
    init(repository: SearchMoviesRepository = DefaultSearchMoviesRepository()) {
        self.repository = repository
    }
    
    func execute(limit: Int) async throws -> [String] {
        try await repository.fetchTrendingTitles(limit: limit)
    }
}
