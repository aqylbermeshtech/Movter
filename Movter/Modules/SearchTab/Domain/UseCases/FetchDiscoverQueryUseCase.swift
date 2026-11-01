//
//  FetchDiscoverQueryUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchDiscoverQueryUseCase {
    func execute(query: DiscoverQuery, page: Int) async throws -> MediaPage
}

final class DefaultFetchDiscoverQueryUseCase: FetchDiscoverQueryUseCase {
    private let repository: SearchMoviesRepository
    
    init(repository: SearchMoviesRepository = DefaultSearchMoviesRepository()) {
        self.repository = repository
    }
    
    func execute(query: DiscoverQuery, page: Int = 1) async throws -> MediaPage {
        guard page >= 1 else {
            throw SearchError.invalidPage(page)
        }
        
        return try await repository.fetchDiscover(query: query, page: page)
    }
}
