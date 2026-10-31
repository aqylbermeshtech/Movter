//
//  ReviewsListViewModel.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation
import UIKit

final class ReviewsListViewModel {

    // MARK: - State & Output
    private(set) var state: ViewState<[Review]> = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((ViewState<[Review]>) -> Void)?

    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let calculateStatsUseCase: CalculateReviewStatsUseCase

    private(set) var reviews: [Review] = []

    init(
        fetchReviewsUseCase: FetchReviewsUseCase = DefaultFetchReviewsUseCase(repository: DefaultReviewsRepository()),
        deleteReviewUseCase: DeleteReviewUseCase = DefaultDeleteReviewUseCase(repository: DefaultReviewsRepository()),
        calculateStatsUseCase: CalculateReviewStatsUseCase = DefaultCalculateReviewStatsUseCase()
    ) {
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.deleteReviewUseCase = deleteReviewUseCase
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    convenience init(store: ReviewStoring) {
        let repo = DefaultReviewsRepository()
        self.init(
            fetchReviewsUseCase: DefaultFetchReviewsUseCase(repository: repo),
            deleteReviewUseCase: DefaultDeleteReviewUseCase(repository: repo),
            calculateStatsUseCase: DefaultCalculateReviewStatsUseCase()
        )
    }

    var summaryText: String? {
        guard !reviews.isEmpty else { return nil }
        let summary = calculateStatsUseCase.execute(reviews: reviews)
        return summary.displayText
    }

    // MARK: - Actions

    func load() {
        state = .loading
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let fetched = try await self.fetchReviewsUseCase.execute()
                await MainActor.run {
                    self.reviews = fetched
                    if fetched.isEmpty {
                        self.state = .empty(message: "No reviews yet. Rate a film to add your first review!")
                    } else {
                        self.state = .loaded(fetched)
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .failure(message: error.localizedDescription)
                }
            }
        }
    }

    func review(at indexPath: IndexPath) -> Review? {
        reviews[safe: indexPath.row]
    }

    func delete(at indexPath: IndexPath) {
        guard let review = review(at: indexPath) else { return }
        let originalReviews = reviews
        reviews.remove(at: indexPath.row)
        state = reviews.isEmpty ? .empty(message: "No reviews yet.") : .loaded(reviews)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.deleteReviewUseCase.execute(id: review.id)
            } catch {
                await MainActor.run {
                    self.reviews = originalReviews
                    self.state = .failure(message: "Failed to delete review: \(error.localizedDescription)")
                }
            }
        }
    }
}
