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

    private let store: LocalJSONFileStore

    init(userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.store = LocalJSONFileStore(
            queueLabel: "com.nurtore.movter.reviews.localstorage",
            userIDProvider: userIDProvider
        )
    }

    func loadReviews() throws -> [Review] {
        try store.loadArray(prefix: "reviews")
    }

    func saveReviews(_ reviews: [Review]) throws {
        try store.saveArray(reviews, prefix: "reviews")
    }
}

