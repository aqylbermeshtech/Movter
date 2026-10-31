//
//  DeleteReviewUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol DeleteReviewUseCase {
    func execute(id: UUID) async throws
}

final class DefaultDeleteReviewUseCase: DeleteReviewUseCase {
    private let repository: ReviewsRepository

    init(repository: ReviewsRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.deleteReview(id: id)
    }
}

