//
//  PFedRecGlobalBackbone.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Represents the shared global item backbone in the PFedRec architecture.
/// Maintains shared representations for movie features across clients.
/// Only this module's accumulated weight deltas are exported for federated aggregation.
final class PFedRecGlobalBackbone: @unchecked Sendable {
    static let dimension = 32

    private let lock = NSLock()
    private var weights: [Float] // 32 x 32 matrix (flat array of 1024 floats)
    private var biases: [Float]  // 32 floats

    // Federated learning gradient accumulation buffer
    private var accumulatedWeightDeltas: [Float]
    private var accumulatedBiasDeltas: [Float]
    private var accumulatedSamples: Int = 0

    init() {
        let size = Self.dimension * Self.dimension
        var initialWeights = [Float](repeating: 0.0, count: size)
        // Initialize as Identity matrix so initial pass preserves canonical feature scale
        for i in 0..<Self.dimension {
            initialWeights[i * Self.dimension + i] = 1.0
        }
        self.weights = initialWeights
        self.biases = [Float](repeating: 0.0, count: Self.dimension)
        self.accumulatedWeightDeltas = [Float](repeating: 0.0, count: size)
        self.accumulatedBiasDeltas = [Float](repeating: 0.0, count: Self.dimension)
    }

    /// Forward pass through the shared item representation layer: h = W_backbone * x + b
    func forward(input: [Float]) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        let dim = Self.dimension
        guard input.count == dim else { return input }

        var output = [Float](repeating: 0.0, count: dim)
        for i in 0..<dim {
            var sum = biases[i]
            let offset = i * dim
            for j in 0..<dim {
                sum += weights[offset + j] * input[j]
            }
            output[i] = sum
        }
        return output
    }

    /// Accumulates parameter updates from backpropagation for federated aggregation
    func recordGradient(input: [Float], gradOutput: [Float], learningRate: Float = 0.01) {
        lock.lock()
        defer { lock.unlock() }

        let dim = Self.dimension
        guard input.count == dim, gradOutput.count == dim else { return }

        for i in 0..<dim {
            let g = gradOutput[i]
            accumulatedBiasDeltas[i] -= learningRate * g
            biases[i] -= learningRate * g

            let rowOffset = i * dim
            for j in 0..<dim {
                let delta = learningRate * g * input[j]
                accumulatedWeightDeltas[rowOffset + j] -= delta
                weights[rowOffset + j] -= delta
            }
        }
        accumulatedSamples += 1
    }

    /// Packages accumulated updates into a federated delta payload for Flower / FL aggregation.
    func exportFederatedDelta(roundID: String = UUID().uuidString) -> FederatedWeightDelta {
        lock.lock()
        defer { lock.unlock() }

        return FederatedWeightDelta(
            clientRoundID: roundID,
            backboneWeightDeltas: accumulatedWeightDeltas,
            backboneBiasDeltas: accumulatedBiasDeltas,
            numSamples: accumulatedSamples
        )
    }

    /// Applies aggregated global weights received from the federated server.
    func applyAggregatedWeights(weights: [Float], biases: [Float]) {
        lock.lock()
        defer { lock.unlock() }

        guard weights.count == self.weights.count, biases.count == self.biases.count else { return }
        self.weights = weights
        self.biases = biases
    }

    /// Clears the accumulated delta buffer after successful federated synchronization.
    func resetAccumulatedDeltas() {
        lock.lock()
        defer { lock.unlock() }

        accumulatedWeightDeltas = [Float](repeating: 0.0, count: accumulatedWeightDeltas.count)
        accumulatedBiasDeltas = [Float](repeating: 0.0, count: accumulatedBiasDeltas.count)
        accumulatedSamples = 0
    }
}
