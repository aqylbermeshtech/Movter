//
//  PFedRecRecommendationEngineTests.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation
import XCTest
@testable import Movter

final class PFedRecRecommendationEngineTests: XCTestCase {

    // Helper to generate mock media
    private func makeMockMedia(
        id: Int,
        title: String,
        genreIds: [Int],
        year: String = "2023",
        voteAverage: Double = 7.8,
        voteCount: Int = 1200
    ) -> Media {
        Media(
            id: id,
            title: title,
            name: nil,
            overview: "Overview for \(title)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: "\(year)-06-01",
            firstAirDate: nil,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genreIds: genreIds
        )
    }

    // MARK: - 1. Feature Representation Tests

    func testMovieFeatureExtractionDimensionsAndValues() {
        let scifiMedia = makeMockMedia(id: 101, title: "Interstellar Space", genreIds: [878, 12], year: "2024", voteAverage: 8.5, voteCount: 15000)
        let vector = MovieFeatureExtractor.extractItemVector(from: scifiMedia)

        XCTAssertEqual(vector.count, 32, "Item feature vector must be exactly 32 dimensions")

        // Sci-Fi (id 878) is index 14, Adventure (id 12) is index 1
        XCTAssertEqual(vector[1], 1.0, "Adventure index should be active")
        XCTAssertEqual(vector[14], 1.0, "Sci-Fi index should be active")
        // Comedy (id 35) is index 3 -> should be 0.0
        XCTAssertEqual(vector[3], 0.0, "Comedy index should be inactive")

        // Year 2024 is era >= 2020 (index 24)
        XCTAssertEqual(vector[24], 1.0, "Era 2020+ index should be active")
        XCTAssertEqual(vector[19], 0.0, "<1980 index should be inactive")

        // Vote average 8.5 / 10.0 = 0.85
        XCTAssertEqual(vector[25], 0.85, accuracy: 0.01)

        // Log vote count should be in [0, 1]
        XCTAssertGreaterThan(vector[26], 0.0)
        XCTAssertLessThanOrEqual(vector[26], 1.0)
    }

    func testSessionContextTrackerUpdatesAffinity() {
        let tracker = SessionContextTracker()
        let initialVector = tracker.makeContextVector()
        XCTAssertEqual(initialVector.count, 24, "Session context vector must be exactly 24 dimensions")

        // Record a like on Sci-Fi (878 -> index 14) with 3.5s dwell
        tracker.recordInteraction(genreIDs: [878], direction: .like, dwellDuration: 3.5)
        let updatedVector = tracker.makeContextVector()

        XCTAssertGreaterThan(updatedVector[14], 0.0, "Liked genre affinity should become positive")

        // Record a pass on Horror (27 -> index 10)
        tracker.recordInteraction(genreIDs: [27], direction: .pass, dwellDuration: 0.6)
        let secondUpdate = tracker.makeContextVector()

        XCTAssertLessThan(secondUpdate[10], 0.0, "Passed genre affinity should become negative")
    }

    // MARK: - 2. Dual Personalization & Local Head Adaptation

    func testPersonalHeadAdaptsToUserLikesAndPasses() {
        let personalHead = PFedRecPersonalHead()
        personalHead.resetWeights()

        let scifiMedia = makeMockMedia(id: 201, title: "Galaxy Odyssey", genreIds: [878])
        let horrorMedia = makeMockMedia(id: 202, title: "Haunted Cabin", genreIds: [27])

        let scifiItem = MovieFeatureExtractor.extractItemVector(from: scifiMedia)
        let horrorItem = MovieFeatureExtractor.extractItemVector(from: horrorMedia)

        let tracker = SessionContextTracker()
        let initialContext = tracker.makeContextVector()

        let scifiInput = scifiItem + initialContext
        let horrorInput = horrorItem + initialContext

        // 1. Train on positive Sci-Fi swipes
        let initialScifiScore = personalHead.predictProbability(input: scifiInput)
        for _ in 0..<5 {
            personalHead.trainStep(input: scifiInput, label: 1.0, lossWeight: 1.5)
        }
        let adaptedScifiScore = personalHead.predictProbability(input: scifiInput)
        XCTAssertGreaterThan(adaptedScifiScore, initialScifiScore, "Liking Sci-Fi should increase its predicted score")

        // 2. Train on negative Horror passes
        let initialHorrorScore = personalHead.predictProbability(input: horrorInput)
        for _ in 0..<5 {
            personalHead.trainStep(input: horrorInput, label: 0.0, lossWeight: 1.3)
        }
        let adaptedHorrorScore = personalHead.predictProbability(input: horrorInput)
        XCTAssertLessThan(adaptedHorrorScore, initialHorrorScore, "Passing Horror should decrease its predicted score")
    }

    func testDwellTimeLossWeighting() {
        // High dwell + like
        let highDwellLike = LocalSwipeInteraction(
            mediaID: 1,
            genreIDs: [878],
            combinedInputVector: [Float](repeating: 0.1, count: 56),
            label: 1.0,
            dwellDuration: 6.0
        )

        // Low dwell + like
        let lowDwellLike = LocalSwipeInteraction(
            mediaID: 2,
            genreIDs: [878],
            combinedInputVector: [Float](repeating: 0.1, count: 56),
            label: 1.0,
            dwellDuration: 0.5
        )

        XCTAssertGreaterThan(highDwellLike.lossWeight, lowDwellLike.lossWeight, "Long dwell inspection on like should have higher loss weight")

        // Fast rejection (<0.8s) vs prolonged ambivalent pass (3.0s)
        let fastReject = LocalSwipeInteraction(
            mediaID: 3,
            genreIDs: [27],
            combinedInputVector: [Float](repeating: 0.1, count: 56),
            label: 0.0,
            dwellDuration: 0.4
        )
        let ambivalentPass = LocalSwipeInteraction(
            mediaID: 4,
            genreIDs: [27],
            combinedInputVector: [Float](repeating: 0.1, count: 56),
            label: 0.0,
            dwellDuration: 3.0
        )

        XCTAssertGreaterThan(fastReject.lossWeight, ambivalentPass.lossWeight, "Immediate reject should have higher hard negative weight than ambivalent pass")
    }

    // MARK: - 3. Privacy & Zero Network Leakage Boundary

    func testFederatedPayloadExcludesPersonalHead() async {
        let globalBackbone = PFedRecGlobalBackbone()
        let roundID = "round_42"

        // Simulate some gradient records
        globalBackbone.recordGradient(
            input: [Float](repeating: 0.5, count: 32),
            gradOutput: [Float](repeating: 0.02, count: 32)
        )

        let delta = globalBackbone.exportFederatedDelta(roundID: roundID)

        XCTAssertEqual(delta.clientRoundID, roundID)
        XCTAssertEqual(delta.numSamples, 1)
        XCTAssertEqual(delta.backboneWeightDeltas.count, 32 * 32, "Should only contain shared backbone deltas")
        XCTAssertEqual(delta.backboneBiasDeltas.count, 32)

        // Reset
        globalBackbone.resetAccumulatedDeltas()
        let resetDelta = globalBackbone.exportFederatedDelta(roundID: "round_43")
        XCTAssertEqual(resetDelta.numSamples, 0)
        XCTAssertEqual(resetDelta.backboneWeightDeltas.first, 0.0)
    }

    // MARK: - 4. Dynamic Queue Re-Ranking & Pinned Stack Stability

    func testEngineReRanksUpcomingCandidatesWhilePreservingPinnedCards() async throws {
        let movies = [
            makeMockMedia(id: 1, title: "Action Blast", genreIds: [28]),
            makeMockMedia(id: 2, title: "Laugh Factory", genreIds: [35]),
            makeMockMedia(id: 3, title: "Cyber Nebula", genreIds: [878]),
            makeMockMedia(id: 4, title: "Quiet Solitude", genreIds: [18]),
            makeMockMedia(id: 5, title: "Solaris Eclipse", genreIds: [878])
        ]

        struct MockDeckUseCase: FetchPopularSwipeDeckUseCase {
            let items: [Media]
            func execute(page: Int, excludingIDs: Set<Int>) async throws -> (items: [Media], isLastPage: Bool) {
                let filtered = items.filter { !excludingIDs.contains($0.id) }
                return (filtered, true)
            }
        }

        let engine = PFedRecDeckEngine(fetchDeckUseCase: MockDeckUseCase(items: movies))
        try await engine.start(excludingIDs: [])

        let initialPeek = await engine.peek(count: 5)
        XCTAssertEqual(initialPeek.count, 5)
        let initialFrontID = initialPeek[0].id

        // Consume front card with a strong LIKE on Action
        let consumed = await engine.consumeFrontCard(direction: .like, dwellDuration: 3.0)
        XCTAssertEqual(consumed?.id, initialFrontID)

        let afterSwipePeek = await engine.peek(count: 4)
        XCTAssertEqual(afterSwipePeek.count, 4)

        // The card that was at index 1 is now at index 0 (pinned top visible card)
        XCTAssertEqual(afterSwipePeek[0].id, 2, "The immediately next visible card remains pinned for visual stability")
    }
}
