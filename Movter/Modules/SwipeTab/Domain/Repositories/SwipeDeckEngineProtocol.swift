//
//  SwipeDeckEngineProtocol.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Core interface for the on-device recommendation and candidate scoring engine.
/// Manages candidate pre-fetching, feature extraction, real-time re-ranking,
/// and local adaptation without blocking the main UI thread.
protocol SwipeDeckEngineProtocol: AnyObject {
    /// Initializes candidate pre-fetching and model state.
    func start(excludingIDs: Set<Int>) async throws

    /// Returns up to `count` candidates from the front of the candidate queue.
    func peek(count: Int) async -> [Media]

    /// Consumes the front candidate card, records interaction, triggers gradient update
    /// on the personal head, and re-ranks unpinned candidate cards in the background.
    @discardableResult
    func consumeFrontCard(direction: SwipeDirection, dwellDuration: TimeInterval) async -> Media?

    /// True if no more candidates remain and all remote pages have been exhausted.
    func isExhausted() async -> Bool

    /// True if an asynchronous fetch is currently in flight.
    func isFetching() async -> Bool

    /// Trigger re-fetching when connectivity is restored.
    func retryFetchIfNeeded() async
}
