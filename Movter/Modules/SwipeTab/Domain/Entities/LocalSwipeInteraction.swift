//
//  LocalSwipeInteraction.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Represents a raw user interaction captured strictly on-device.
/// In accordance with PFedRec dual personalization and privacy constraints,
/// this data is never transmitted to any remote backend.
struct LocalSwipeInteraction: Codable, Sendable {
    let mediaID: Int
    let genreIDs: [Int]
    let combinedInputVector: [Float] // Dimension 56
    let label: Float                 // 1.0 = like, 0.0 = pass
    let dwellDuration: TimeInterval  // Seconds spent viewing the card before swipe
    let timestamp: Date

    init(
        mediaID: Int,
        genreIDs: [Int],
        combinedInputVector: [Float],
        label: Float,
        dwellDuration: TimeInterval,
        timestamp: Date = Date()
    ) {
        self.mediaID = mediaID
        self.genreIDs = genreIDs
        self.combinedInputVector = combinedInputVector
        self.label = label
        self.dwellDuration = dwellDuration
        self.timestamp = timestamp
    }

    /// Computes sample loss weight using dwell time.
    /// Positive swipe with prolonged inspection signifies high confidence preference.
    /// Fast pass signifies immediate negative rejection.
    var lossWeight: Float {
        let clampedDwell = Float(min(max(dwellDuration, 0.2), 10.0))
        if label >= 0.5 {
            // Swipe right: longer dwell increases confidence up to 1.7x
            return 1.0 + 0.35 * min(clampedDwell / 4.0, 2.0)
        } else {
            // Swipe left: immediate dismiss (<0.8s) is a strong hard negative
            return clampedDwell < 0.8 ? 1.3 : 0.85
        }
    }
}
