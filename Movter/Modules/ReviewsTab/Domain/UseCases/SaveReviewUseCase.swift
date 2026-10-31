//
//  SaveReviewUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SaveReviewUseCase {
    func execute(_ review: Review) async throws
}

final class DefaultSaveReviewUseCase: SaveReviewUseCase {
    private let repository: ReviewsRepository

    init(repository: ReviewsRepository) {
        self.repository = repository
    }

    func execute(_ review: Review) async throws {
        guard !review.filmTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewError.emptyFilmTitle
        }
        guard Review.scoreRange.contains(review.score) else {
            throw ReviewError.invalidScore(review.score)
        }
        guard review.reviewText.count <= ReviewEditorViewModel.maxReviewLength else {
            throw ReviewError.reviewTooLong(limit: ReviewEditorViewModel.maxReviewLength)
        }
        try await repository.saveReview(review)
    }
}

