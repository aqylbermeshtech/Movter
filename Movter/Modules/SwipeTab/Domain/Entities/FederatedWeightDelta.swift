//
//  FederatedWeightDelta.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Encapsulates model updates for the shared global backbone item representations.
/// Conforms to PFedRec dual personalization: only the shared representation deltas
/// are packaged for federated aggregation (e.g., Flower).
/// The client's personal classification head parameters are strictly omitted.
struct FederatedWeightDelta: Codable, Sendable {
    let clientRoundID: String
    let backboneWeightDeltas: [Float]
    let backboneBiasDeltas: [Float]
    let numSamples: Int
    let timestamp: Date

    init(
        clientRoundID: String,
        backboneWeightDeltas: [Float],
        backboneBiasDeltas: [Float],
        numSamples: Int,
        timestamp: Date = Date()
    ) {
        self.clientRoundID = clientRoundID
        self.backboneWeightDeltas = backboneWeightDeltas
        self.backboneBiasDeltas = backboneBiasDeltas
        self.numSamples = numSamples
        self.timestamp = timestamp
    }
}
