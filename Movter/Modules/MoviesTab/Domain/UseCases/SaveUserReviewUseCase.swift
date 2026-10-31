//
//  SaveUserReviewUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol SaveUserReviewUseCase {
    func execute(_ review: Review) async throws
}

final class DefaultSaveUserReviewUseCase: SaveUserReviewUseCase {
    private let repository: ReviewsRepository
    
    init(repository: ReviewsRepository = DefaultReviewsRepository()) {
        self.repository = repository
    }
    
    func execute(_ review: Review) async throws {
        try await repository.saveReview(review)
    }
}
