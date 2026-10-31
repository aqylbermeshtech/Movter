//
//  DefaultReviewsRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

final class DefaultReviewsRepository: ReviewsRepository {

    private let localDataSource: ReviewsLocalDataSource
    private let queue = DispatchQueue(label: "com.nurtore.movter.reviews.repository")

    init(localDataSource: ReviewsLocalDataSource = LocalFileReviewsDataSource()) {
        self.localDataSource = localDataSource
    }

    func fetchAll() async throws -> [Review] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let reviews = try self.localDataSource.loadReviews().sorted { $0.updatedAt > $1.updatedAt }
                    continuation.resume(returning: reviews)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchReview(for mediaId: Int) async throws -> Review? {
        let reviews = try await fetchAll()
        return reviews.first { $0.tmdbID == mediaId }
    }

    func saveReview(_ review: Review) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    var reviews = try self.localDataSource.loadReviews()
                    var updated = review
                    updated.updatedAt = Date()
                    if let index = reviews.firstIndex(where: { $0.id == review.id }) {
                        reviews[index] = updated
                    } else {
                        reviews.append(updated)
                    }
                    try self.localDataSource.saveReviews(reviews)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteReview(id: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    var reviews = try self.localDataSource.loadReviews()
                    reviews.removeAll { $0.id == id }
                    try self.localDataSource.saveReviews(reviews)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

