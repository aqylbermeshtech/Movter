//
//  GetTrailerUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetTrailerUseCase {
    func execute(for mediaId: Int, type: MediaType) async throws -> String?
}

final class DefaultGetTrailerUseCase: GetTrailerUseCase {
    private let repository: MovieDetailsRepository
    
    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }
    
    func execute(for mediaId: Int, type: MediaType) async throws -> String? {
        try await repository.fetchTrailerKey(for: mediaId, type: type)
    }
}
