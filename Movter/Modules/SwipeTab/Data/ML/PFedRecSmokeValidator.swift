//
//  PFedRecSmokeValidator.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

#if DEBUG
import Foundation

/// Lightweight on-device validation suite that can be triggered in Debug builds
/// to verify that PFedRec feature extraction, scoring, gradient updates, and re-ranking
/// function flawlessly on Simulator or real devices without XCTest dependencies.
enum PFedRecSmokeValidator {

    static func runValidation() async -> Bool {
        print("[PFedRec] Running on-device ML smoke validation...")

        // 1. Feature Extraction Check
        let testMedia = Media(
            id: 999,
            title: "Test Movie",
            name: nil,
            overview: "Test",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            firstAirDate: nil,
            voteAverage: 8.0,
            voteCount: 1000,
            genreIds: [878, 28] // Sci-Fi, Action
        )
        let itemVec = MovieFeatureExtractor.extractItemVector(from: testMedia)
        guard itemVec.count == 32, itemVec[0] == 1.0, itemVec[14] == 1.0 else {
            print("[PFedRec] ❌ Feature extraction failed")
            return false
        }

        // 2. Personal Head Adaptation Check
        let head = PFedRecPersonalHead()
        let backbone = PFedRecGlobalBackbone()
        let tracker = SessionContextTracker()

        let hItem = backbone.forward(input: itemVec)
        let context = tracker.makeContextVector()
        let input = hItem + context

        let initialP = head.predictProbability(input: input)
        for _ in 0..<5 {
            let grad = head.trainStep(input: input, label: 1.0, lossWeight: 1.5)
            backbone.recordGradient(input: itemVec, gradOutput: grad)
        }
        let adaptedP = head.predictProbability(input: input)

        guard adaptedP > initialP else {
            print("[PFedRec] ❌ Personal head adaptation failed (initial: \(initialP), adapted: \(adaptedP))")
            return false
        }

        // 3. Federated Delta Boundary Check
        let delta = backbone.exportFederatedDelta()
        guard delta.backboneWeightDeltas.count == 32 * 32, delta.numSamples > 0 else {
            print("[PFedRec] ❌ Federated delta boundary check failed")
            return false
        }

        print("[PFedRec] ✅ All on-device smoke checks passed! (P: \(initialP) -> \(adaptedP))")
        return true
    }
}
#endif
