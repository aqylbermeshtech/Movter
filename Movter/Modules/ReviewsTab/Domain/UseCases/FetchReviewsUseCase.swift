//
//  FetchReviewsUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FetchReviewsUseCase {
    func execute() async throws -> [Review]
}

final class DefaultFetchReviewsUseCase: FetchReviewsUseCase {
    private let repository: ReviewsRepository

    init(repository: ReviewsRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Review] {
        try await repository.fetchAll()
    }
}

