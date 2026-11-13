//
//  CandidateCard.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

struct CandidateCard: Identifiable, Sendable {
    let media: Media
    let itemFeatureVector: [Float] // Dimension 32
    var predictedScore: Float      // P(Swipe Right) in [0.0, 1.0]
    let fetchedAt: Date

    var id: Int { media.id }

    init(
        media: Media,
        itemFeatureVector: [Float],
        predictedScore: Float = 0.5,
        fetchedAt: Date = Date()
    ) {
        self.media = media
        self.itemFeatureVector = itemFeatureVector
        self.predictedScore = predictedScore
        self.fetchedAt = fetchedAt
    }
}
