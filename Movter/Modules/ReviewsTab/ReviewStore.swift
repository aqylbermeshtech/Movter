//
//  ReviewStore.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation
import FirebaseAuth

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

    private let userIDProvider: () -> String?
    private let queue = DispatchQueue(label: "com.nurtore.movter.reviewstore")

    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userID = userIDProvider() ?? "local"
        return documents.appendingPathComponent("reviews-\(userID).json")
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.userIDProvider = userIDProvider
    }

    // MARK: - Modern Async APIs

    func fetchAll() async throws -> [Review] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let reviews = try self.readFromDisk().sorted { $0.updatedAt > $1.updatedAt }
                    continuation.resume(returning: reviews)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(_ review: Review) async throws {
        try await withCheckedThrowingContinuation { continuation in
            mutate(completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }) { reviews in
                var updated = review
                updated.updatedAt = Date()
                if let index = reviews.firstIndex(where: { $0.id == review.id }) {
                    reviews[index] = updated
                } else {
                    reviews.append(updated)
                }
            }
        }
    }

    func delete(_ reviewID: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            mutate(completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }) { reviews in
                reviews.removeAll { $0.id == reviewID }
            }
        }
    }

    // MARK: - Completion-based APIs

    func fetchAll(completion: @escaping (Result<[Review], Error>) -> Void) {
        queue.async {
            let result = Result { try self.readFromDisk() }
                .map { $0.sorted { $0.updatedAt > $1.updatedAt } }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func save(_ review: Review, completion: @escaping (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { reviews in
            var updated = review
            updated.updatedAt = Date()
            if let index = reviews.firstIndex(where: { $0.id == review.id }) {
                reviews[index] = updated
            } else {
                reviews.append(updated)
            }
        }
    }

    func delete(_ reviewID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        mutate(completion: completion) { reviews in
            reviews.removeAll { $0.id == reviewID }
        }
    }

    // MARK: - Disk

    private func mutate(
        completion: @escaping (Result<Void, Error>) -> Void,
        _ changes: @escaping (inout [Review]) -> Void
    ) {
        queue.async {
            let result = Result {
                var reviews = try self.readFromDisk()
                changes(&reviews)
                try self.writeToDisk(reviews)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func readFromDisk() throws -> [Review] {
        let targetURL = fileURL
        guard FileManager.default.fileExists(atPath: targetURL.path) else { return [] }
        let data = try Data(contentsOf: targetURL)
        guard !data.isEmpty else { return [] }
        return try decoder.decode([Review].self, from: data)
    }

    private func writeToDisk(_ reviews: [Review]) throws {
        let targetURL = fileURL
        let data = try encoder.encode(reviews)
        try data.write(to: targetURL, options: .atomic)
    }
}
