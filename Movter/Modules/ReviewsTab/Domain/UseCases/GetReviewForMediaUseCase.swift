//
//  GetReviewForMediaUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol GetReviewForMediaUseCase {
    func execute(mediaId: Int) async throws -> Review?
}

final class DefaultGetReviewForMediaUseCase: GetReviewForMediaUseCase {
    private let repository: ReviewsRepository

    init(repository: ReviewsRepository) {
        self.repository = repository
    }

    func execute(mediaId: Int) async throws -> Review? {
        try await repository.fetchReview(for: mediaId)
    }
}

