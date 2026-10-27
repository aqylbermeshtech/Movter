//
//  GetUserReviewForMovieUseCase.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol GetUserReviewForMovieUseCase {
    func execute(for mediaId: Int) async throws -> Review?
}

final class DefaultGetUserReviewForMovieUseCase: GetUserReviewForMovieUseCase {
    private let repository: ReviewsRepository
    
    init(repository: ReviewsRepository) {
        self.repository = repository
    }
    
    func execute(for mediaId: Int) async throws -> Review? {
        try await repository.fetchReview(for: mediaId)
    }
}
