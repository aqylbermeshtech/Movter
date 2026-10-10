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
    private let store: ReviewStoring
    private(set) var reviews: [Review] = []
    init(store: ReviewStoring = ReviewStoreFactory.makeStore()) {
        self.store = store
    }
    
    var isEmpty: Bool { reviews.isEmpty }
    var summaryText: String? {
        guard !reviews.isEmpty else { return nil }
        let average = Double(reviews.reduce(0) { $0 + $1.score }) / Double(reviews.count)
        let filmCount = "\(reviews.count) film\(reviews.count == 1 ? "" : "s")"
        return String(format: "%@  ·  %.1f average", filmCount, average)
    }
    
    // MARK: - Actions
    func load() {
        state = .loading
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let fetched = try await self.store.fetchAll()
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
                try await self.store.delete(review.id)
            } catch {
                await MainActor.run {
                    self.reviews = originalReviews
                    self.state = .failure(message: "Failed to delete review: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func makeEditorViewModel(for review: Review?) -> ReviewEditorViewModel {
        ReviewEditorViewModel(
            store: store,
            mode: review.map { .edit($0) } ?? .create
        )
    }
}
