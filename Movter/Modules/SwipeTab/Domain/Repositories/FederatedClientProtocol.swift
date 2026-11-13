//
//  FederatedClientProtocol.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Defines the federated learning aggregation boundary.
/// Under PFedRec (Personalized Federated Recommendation), the server only aggregates
/// shared item backbone representations, while the client maintains its own private
/// classification head.
protocol FederatedClientProtocol: AnyObject {
    /// Packages accumulated gradient/weight deltas for the shared item backbone.
    func exportSharedBackboneDeltas() async -> FederatedWeightDelta

    /// Receives updated shared item backbone representations aggregated across clients.
    func applyAggregatedBackboneWeights(weights: [Float], biases: [Float]) async

    /// Clears the accumulated parameter delta buffer after successful server transmission.
    func resetAccumulatedDeltas() async
}
