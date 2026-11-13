//
//  GetMovieCreditsUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetMovieCreditsUseCase {
    func execute(for mediaId: Int, type: MediaType) async throws -> MovieCredits
}

final class DefaultGetMovieCreditsUseCase: GetMovieCreditsUseCase {
    private let repository: MovieDetailsRepository
    
    init(repository: MovieDetailsRepository = DefaultMovieDetailsRepository()) {
        self.repository = repository
    }
    
    func execute(for mediaId: Int, type: MediaType) async throws -> MovieCredits {
        try await repository.fetchCredits(for: mediaId, type: type)
    }
}
