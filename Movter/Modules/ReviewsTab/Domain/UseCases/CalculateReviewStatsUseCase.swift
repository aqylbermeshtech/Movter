//
//  CalculateReviewStatsUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol CalculateReviewStatsUseCase {
    func execute(reviews: [Review]) -> ReviewSummary
}

final class DefaultCalculateReviewStatsUseCase: CalculateReviewStatsUseCase {
    func execute(reviews: [Review]) -> ReviewSummary {
        ReviewSummary(reviews: reviews)
    }
}

