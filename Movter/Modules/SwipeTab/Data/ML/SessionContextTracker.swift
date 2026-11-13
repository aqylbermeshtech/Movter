//
//  SessionContextTracker.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Maintains intra-session context and dynamic user preference shifts.
/// Completely local to the active session; never exposed or transmitted externally.
final class SessionContextTracker: @unchecked Sendable {
    static let contextFeatureDimension = 24

    private let lock = NSLock()
    private var genreAffinity: [Float] // Dimension 19
    private var sessionSwipeCount: Int = 0
    private var avgLikeDwell: Float = 2.0
    private var avgPassDwell: Float = 1.0
    private let decayFactor: Float = 0.82

    init() {
        self.genreAffinity = [Float](repeating: 0.0, count: MovieFeatureExtractor.standardGenreIDs.count)
    }

    /// Records an interaction and updates short-term preference state.
    func recordInteraction(
        genreIDs: [Int],
        direction: SwipeDirection,
        dwellDuration: TimeInterval
    ) {
        lock.lock()
        defer { lock.unlock() }

        sessionSwipeCount += 1
        let dwell = Float(dwellDuration)
        let genreSet = Set(genreIDs)

        for (idx, gid) in MovieFeatureExtractor.standardGenreIDs.enumerated() {
            let present = genreSet.contains(gid)
            if present {
                let delta: Float = (direction == .like) ? 1.0 : -0.6
                genreAffinity[idx] = (genreAffinity[idx] * decayFactor) + (delta * (1.0 - decayFactor))
            } else {
                genreAffinity[idx] = genreAffinity[idx] * decayFactor
            }
            // Clamp affinity between -1.0 and 1.0
            genreAffinity[idx] = min(max(genreAffinity[idx], -1.0), 1.0)
        }

        if direction == .like {
            avgLikeDwell = (avgLikeDwell * 0.7) + (dwell * 0.3)
        } else {
            avgPassDwell = (avgPassDwell * 0.7) + (dwell * 0.3)
        }
    }

    /// Generates current 24-dimensional session context vector.
    func makeContextVector(currentDate: Date = Date()) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        var vector = [Float](repeating: 0.0, count: Self.contextFeatureDimension)

        // 1. Short-term Genre Affinity (Indices 0..<19)
        for i in 0..<19 {
            vector[i] = genreAffinity[i]
        }

        // 2. Session Progress (Index 19): [0.0, 1.0]
        vector[19] = min(Float(sessionSwipeCount) / 10.0, 1.0)

        // 3. Normalized Dwell Time Momentum (Indices 20, 21)
        vector[20] = min(avgLikeDwell / 6.0, 1.0)
        vector[21] = min(avgPassDwell / 6.0, 1.0)

        // 4. Temporal Cyclical Features (Indices 22, 23)
        let calendar = Calendar.current
        let hour = Float(calendar.component(.hour, from: currentDate))
        let minute = Float(calendar.component(.minute, from: currentDate))
        let timeInHours = hour + (minute / 60.0)
        let angle = (2.0 * Float.pi * timeInHours) / 24.0

        vector[22] = sinf(angle)
        vector[23] = cosf(angle)

        return vector
    }

    /// Resets intra-session state for a new swiping session.
    func resetSession() {
        lock.lock()
        defer { lock.unlock() }

        genreAffinity = [Float](repeating: 0.0, count: MovieFeatureExtractor.standardGenreIDs.count)
        sessionSwipeCount = 0
        avgLikeDwell = 2.0
        avgPassDwell = 1.0
    }
}
