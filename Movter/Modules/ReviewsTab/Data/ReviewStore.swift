//
//  ReviewStore.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation

protocol ReviewStoring: AnyObject {
    func fetchAll() async throws -> [Review]
    func save(_ review: Review) async throws
    func delete(_ reviewID: UUID) async throws
    func fetchReview(forTMDBID tmdbID: Int) async throws -> Review?

    // MARK: - Backward-Compatible Completion APIs
    func fetchAll(completion: @escaping (Result<[Review], Error>) -> Void)
    func save(_ review: Review, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(_ reviewID: UUID, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchReview(forTMDBID tmdbID: Int, completion: @escaping (Result<Review?, Error>) -> Void)
}

extension ReviewStoring {
    func fetchReview(forTMDBID tmdbID: Int) async throws -> Review? {
        let reviews = try await fetchAll()
        return reviews.first { $0.tmdbID == tmdbID }
    }

    func fetchReview(forTMDBID tmdbID: Int, completion: @escaping (Result<Review?, Error>) -> Void) {
        fetchAll { result in
            completion(result.map { reviews in
                reviews.first { $0.tmdbID == tmdbID }
            })
        }
    }
}

enum ReviewStoreFactory {
    static func makeStore() -> ReviewStoring {
        LocalReviewStore()
    }
}

final class LocalReviewStore: ReviewStoring {

    private let repository: ReviewsRepository

    init(repository: ReviewsRepository = DefaultReviewsRepository()) {
        self.repository = repository
    }

    // MARK: - Modern Async APIs

    func fetchAll() async throws -> [Review] {
        try await repository.fetchAll()
    }

    func save(_ review: Review) async throws {
        try await repository.saveReview(review)
    }

    func delete(_ reviewID: UUID) async throws {
        try await repository.deleteReview(id: reviewID)
    }

    func fetchReview(forTMDBID tmdbID: Int) async throws -> Review? {
        try await repository.fetchReview(for: tmdbID)
    }

    // MARK: - Completion-based APIs

    func fetchAll(completion: @escaping (Result<[Review], Error>) -> Void) {
        Task {
            do {
                let reviews = try await repository.fetchAll()
                DispatchQueue.main.async { completion(.success(reviews)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func save(_ review: Review, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await repository.saveReview(review)
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func delete(_ reviewID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await repository.deleteReview(id: reviewID)
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func fetchReview(forTMDBID tmdbID: Int, completion: @escaping (Result<Review?, Error>) -> Void) {
        Task {
            do {
                let review = try await repository.fetchReview(for: tmdbID)
                DispatchQueue.main.async { completion(.success(review)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
