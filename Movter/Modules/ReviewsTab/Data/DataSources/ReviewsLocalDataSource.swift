//
//  ReviewsLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation
import FirebaseAuth

protocol ReviewsLocalDataSource: AnyObject {
    func loadReviews() throws -> [Review]
    func saveReviews(_ reviews: [Review]) throws
}

final class LocalFileReviewsDataSource: ReviewsLocalDataSource {

    private let userIDProvider: () -> String?
    private let queue = DispatchQueue(label: "com.nurtore.movter.reviews.localstorage")

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

    func loadReviews() throws -> [Review] {
        try queue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return []
            }
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([Review].self, from: data)
        }
    }

    func saveReviews(_ reviews: [Review]) throws {
        try queue.sync {
            let data = try encoder.encode(reviews)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}

