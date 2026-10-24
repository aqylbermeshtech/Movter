//
//  GetSimilarMoviesUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetSimilarMoviesUseCase {
    func execute(for mediaId: Int, type: MediaType, limit: Int) async throws -> [Media]
}

final class DefaultGetSimilarMoviesUseCase: GetSimilarMoviesUseCase {
    private let repository: MovieDetailsRepository
    
    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }
    
    func execute(for mediaId: Int, type: MediaType, limit: Int) async throws -> [Media] {
        try await repository.fetchSimilar(for: mediaId, type: type, limit: limit)
    }
}
