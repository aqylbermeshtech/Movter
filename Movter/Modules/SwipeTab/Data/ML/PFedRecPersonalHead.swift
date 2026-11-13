//
//  PFedRecPersonalHead.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// The private on-device personalized classification head in PFedRec.
/// Resides strictly on user storage; weights are NEVER shared with or transmitted to any server.
/// Implements vectorized forward inference and backpropagation with momentum optimization.
final class PFedRecPersonalHead: @unchecked Sendable {
    static let inputDimension = 56   // 32 item + 24 session
    static let hiddenDimension = 24  // Hidden layer width
    static let outputDimension = 1

    private let lock = NSLock()

    // Layer 1: [24 x 56]
    private var w1: [Float] // Size: 24 * 56 = 1344
    private var b1: [Float] // Size: 24
    private var v_w1: [Float]
    private var v_b1: [Float]

    // Layer 2: [1 x 24]
    private var w2: [Float] // Size: 24
    private var b2: Float
    private var v_w2: [Float]
    private var v_b2: Float

    // Hyperparameters
    private let learningRate: Float = 0.05
    private let momentum: Float = 0.75
    private let l2Regularization: Float = 0.0005

    private let storageKey = "com.nurtore.movter.pfedrec.personal_head_weights"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let w1Count = Self.hiddenDimension * Self.inputDimension
        let b1Count = Self.hiddenDimension
        let w2Count = Self.hiddenDimension

        self.w1 = [Float](repeating: 0.0, count: w1Count)
        self.b1 = [Float](repeating: 0.0, count: b1Count)
        self.v_w1 = [Float](repeating: 0.0, count: w1Count)
        self.v_b1 = [Float](repeating: 0.0, count: b1Count)

        self.w2 = [Float](repeating: 0.0, count: w2Count)
        self.b2 = 0.0
        self.v_w2 = [Float](repeating: 0.0, count: w2Count)
        self.v_b2 = 0.0

        if !loadPersistedWeights() {
            initializeWeights()
        }
    }

    // MARK: - Forward Pass

    /// Computes P(SwipeRight | input) in (0.0, 1.0).
    func predictProbability(input: [Float]) -> Float {
        lock.lock()
        defer { lock.unlock() }

        return forwardInternal(input: input).output
    }

    private struct ForwardCache {
        let z1: [Float]
        let a1: [Float]
        let z2: Float
        let output: Float
    }

    private func forwardInternal(input: [Float]) -> ForwardCache {
        let inDim = Self.inputDimension
        let hidDim = Self.hiddenDimension

        // 1. z1 = W1 * input + b1
        var z1 = [Float](repeating: 0.0, count: hidDim)
        for j in 0..<hidDim {
            var sum = b1[j]
            let offset = j * inDim
            for k in 0..<inDim {
                sum += w1[offset + k] * input[k]
            }
            z1[j] = sum
        }

        // 2. a1 = GELU(z1) & z2 = W2 * a1 + b2
        var a1 = [Float](repeating: 0.0, count: hidDim)
        var z2 = b2
        for j in 0..<hidDim {
            let act = Self.gelu(z1[j])
            a1[j] = act
            z2 += w2[j] * act
        }

        // 3. output = sigmoid(z2)
        let output = Self.sigmoid(z2)

        return ForwardCache(z1: z1, a1: a1, z2: z2, output: output)
    }

    // MARK: - Local Training Step (Backprop with Dwell Weight)

    /// Performs an on-device gradient update step on the personalized head.
    /// Returns the backpropagated gradient with respect to the input item features (dimension 32)
    /// to update the shared backbone.
    @discardableResult
    func trainStep(
        input: [Float],
        label: Float,
        lossWeight: Float
    ) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        guard input.count == Self.inputDimension else {
            return [Float](repeating: 0.0, count: 32)
        }

        let cache = forwardInternal(input: input)
        let delta2 = lossWeight * (cache.output - label)

        // Gradients for Layer 2:
        for j in 0..<Self.hiddenDimension {
            let gradW2 = delta2 * cache.a1[j] + l2Regularization * w2[j]
            v_w2[j] = momentum * v_w2[j] + learningRate * gradW2
            w2[j] -= v_w2[j]
        }
        v_b2 = momentum * v_b2 + learningRate * delta2
        b2 -= v_b2

        // Backprop to Layer 1:
        var delta1 = [Float](repeating: 0.0, count: Self.hiddenDimension)
        for j in 0..<Self.hiddenDimension {
            let geluGrad = Self.geluDerivative(cache.z1[j])
            delta1[j] = (w2[j] * delta2) * geluGrad
        }

        // Gradients for Layer 1:
        let inDim = Self.inputDimension
        for j in 0..<Self.hiddenDimension {
            let d1 = delta1[j]
            let offset = j * inDim
            for k in 0..<inDim {
                let gradW1 = d1 * input[k] + l2Regularization * w1[offset + k]
                v_w1[offset + k] = momentum * v_w1[offset + k] + learningRate * gradW1
                w1[offset + k] -= v_w1[offset + k]
            }
            v_b1[j] = momentum * v_b1[j] + learningRate * d1
            b1[j] -= v_b1[j]
        }

        // Backpropagated gradient to input item features (first 32 dimensions)
        var gradItemInput = [Float](repeating: 0.0, count: 32)
        for k in 0..<32 {
            var sum: Float = 0.0
            for j in 0..<Self.hiddenDimension {
                sum += w1[j * inDim + k] * delta1[j]
            }
            gradItemInput[k] = sum
        }

        persistWeights()
        return gradItemInput
    }

    // MARK: - Mathematical Activations

    private static func sigmoid(_ x: Float) -> Float {
        let clamped = min(max(x, -15.0), 15.0)
        return 1.0 / (1.0 + expf(-clamped))
    }

    private static func gelu(_ x: Float) -> Float {
        return x * sigmoid(1.702 * x)
    }

    private static func geluDerivative(_ x: Float) -> Float {
        let s = sigmoid(1.702 * x)
        return s + 1.702 * x * s * (1.0 - s)
    }

    // MARK: - Initialization

    private func initializeWeights() {
        let std1 = sqrtf(2.0 / Float(Self.inputDimension))
        for i in 0..<w1.count {
            w1[i] = Float.random(in: -std1...std1)
        }
        for i in 0..<b1.count {
            b1[i] = 0.0
        }

        for i in 0..<w2.count {
            w2[i] = Float.random(in: 0.04...0.12)
        }
        b2 = 0.0
    }

    // MARK: - Local Persistence (Zero Network Leakage)

    private struct PersistedHead: Codable {
        let w1: [Float]
        let b1: [Float]
        let w2: [Float]
        let b2: Float
    }

    private func persistWeights() {
        let payload = PersistedHead(w1: w1, b1: b1, w2: w2, b2: b2)
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func loadPersistedWeights() -> Bool {
        guard let data = defaults.data(forKey: storageKey),
              let payload = try? JSONDecoder().decode(PersistedHead.self, from: data),
              payload.w1.count == w1.count,
              payload.b1.count == b1.count,
              payload.w2.count == w2.count else {
            return false
        }
        self.w1 = payload.w1
        self.b1 = payload.b1
        self.w2 = payload.w2
        self.b2 = payload.b2
        return true
    }

    /// Resets personal head weights to clean slate
    func resetWeights() {
        lock.lock()
        defer { lock.unlock() }

        defaults.removeObject(forKey: storageKey)
        let w1Count = Self.hiddenDimension * Self.inputDimension
        v_w1 = [Float](repeating: 0.0, count: w1Count)
        v_b1 = [Float](repeating: 0.0, count: Self.hiddenDimension)
        v_w2 = [Float](repeating: 0.0, count: Self.hiddenDimension)
        v_b2 = 0.0
        initializeWeights()
    }
}
