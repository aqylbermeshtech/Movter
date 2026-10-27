//
//  FetchDiscoverMediaUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol FetchDiscoverMediaUseCase {
    func execute(genre: MovieGenre, page: Int) async throws -> [Media]
}

final class DefaultFetchDiscoverMediaUseCase: FetchDiscoverMediaUseCase {
    private let repository: MoviesRepository
    
    init(repository: MoviesRepository) {
        self.repository = repository
    }
    
    func execute(genre: MovieGenre, page: Int) async throws -> [Media] {
        try await repository.fetchDiscover(genre: genre, page: page)
    }
}
