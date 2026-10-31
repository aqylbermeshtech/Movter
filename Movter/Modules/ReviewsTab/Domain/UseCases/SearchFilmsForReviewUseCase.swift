//
//  SearchFilmsForReviewUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SearchFilmsForReviewUseCase {
    func execute(query: String, page: Int) async throws -> [Media]
}

final class DefaultSearchFilmsForReviewUseCase: SearchFilmsForReviewUseCase {
    private let repository: FilmSearchRepository

    init(repository: FilmSearchRepository) {
        self.repository = repository
    }

    func execute(query: String, page: Int = 1) async throws -> [Media] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        return try await repository.searchFilms(query: trimmed, page: page)
    }
}

