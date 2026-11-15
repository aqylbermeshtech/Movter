//
//  SearchMoviesUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SearchMoviesUseCase {
    func execute(query: String, page: Int) async throws -> MediaPage
}

final class DefaultSearchMoviesUseCase: SearchMoviesUseCase {
    private let repository: SearchMoviesRepository
    
    init(repository: SearchMoviesRepository = DefaultSearchMoviesRepository()) {
        self.repository = repository
    }
    
    func execute(query: String, page: Int) async throws -> MediaPage {
        try await repository.searchMovies(query: query, page: page)
    }
}
