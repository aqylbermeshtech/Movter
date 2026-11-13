//
//  PFedRecDeckEngine.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

/// Core background actor coordinating on-device recommendation, feature extraction,
/// real-time model adaptation (PFedRec), and candidate queue management.
actor PFedRecDeckEngine: SwipeDeckEngineProtocol, FederatedClientProtocol {

    private let fetchDeckUseCase: FetchPopularSwipeDeckUseCase
    private let globalBackbone: PFedRecGlobalBackbone
    private let personalHead: PFedRecPersonalHead
    private let sessionTracker: SessionContextTracker
    private let localInteractionSource: LocalInteractionDataSource

    private var candidatePool: [CandidateCard] = []
    private var excludedIDs: Set<Int> = []
    private var currentPage: Int = 1
    private var isFetchingCandidates: Bool = false
    private var isRemoteExhausted: Bool = false

    private let prefetchThreshold: Int = 6

    init(
        fetchDeckUseCase: FetchPopularSwipeDeckUseCase = DefaultFetchPopularSwipeDeckUseCase(),
        globalBackbone: PFedRecGlobalBackbone = PFedRecGlobalBackbone(),
        personalHead: PFedRecPersonalHead = PFedRecPersonalHead(),
        sessionTracker: SessionContextTracker = SessionContextTracker(),
        localInteractionSource: LocalInteractionDataSource = UserDefaultsInteractionDataSource()
    ) {
        self.fetchDeckUseCase = fetchDeckUseCase
        self.globalBackbone = globalBackbone
        self.personalHead = personalHead
        self.sessionTracker = sessionTracker
        self.localInteractionSource = localInteractionSource
    }

    // MARK: - SwipeDeckEngineProtocol

    func start(excludingIDs: Set<Int>) async throws {
        self.excludedIDs.formUnion(excludingIDs)
        self.sessionTracker.resetSession()

        // Replay a small batch of recent local interactions to warm-start session if needed
        warmStartFromRecentInteractions()

        if candidatePool.isEmpty {
            try await fetchMoreCandidates()
        }
    }

    func peek(count: Int) async -> [Media] {
        let items = candidatePool.prefix(count).map(\.media)
        return Array(items)
    }

    @discardableResult
    func consumeFrontCard(direction: SwipeDirection, dwellDuration: TimeInterval) async -> Media? {
        guard !candidatePool.isEmpty else { return nil }

        let consumed = candidatePool.removeFirst()
        excludedIDs.insert(consumed.id)

        // 1. Update session context
        let genreIDs = consumed.media.genreIds ?? []
        sessionTracker.recordInteraction(
            genreIDs: genreIDs,
            direction: direction,
            dwellDuration: dwellDuration
        )

        // 2. Build input vector: [h_item (32) || s_context (24)]
        let hItem = globalBackbone.forward(input: consumed.itemFeatureVector)
        let sContext = sessionTracker.makeContextVector()
        var combinedInput = [Float]()
        combinedInput.reserveCapacity(56)
        combinedInput.append(contentsOf: hItem)
        combinedInput.append(contentsOf: sContext)

        let label: Float = (direction == .like) ? 1.0 : 0.0

        // 3. Record local interaction (strictly on-device storage)
        let interaction = LocalSwipeInteraction(
            mediaID: consumed.id,
            genreIDs: genreIDs,
            combinedInputVector: combinedInput,
            label: label,
            dwellDuration: dwellDuration
        )
        localInteractionSource.recordInteraction(interaction)

        // 4. Perform gradient update on personal head
        let gradItem = personalHead.trainStep(
            input: combinedInput,
            label: label,
            lossWeight: interaction.lossWeight
        )

        // 5. Backpropagate item gradients into global backbone for federated aggregation
        globalBackbone.recordGradient(
            input: consumed.itemFeatureVector,
            gradOutput: gradItem
        )

        // 6. Asynchronously re-score and re-rank remaining unpinned cards in memory
        rescoreAndRerankCandidates()

        // 7. Background prefetch if queue is running low
        if candidatePool.count <= prefetchThreshold && !isRemoteExhausted && !isFetchingCandidates {
            Task { [weak self] in
                try? await self?.fetchMoreCandidates()
            }
        }

        return consumed.media
    }

    func isExhausted() async -> Bool {
        return candidatePool.isEmpty && isRemoteExhausted && !isFetchingCandidates
    }

    func isFetching() async -> Bool {
        return isFetchingCandidates
    }

    func retryFetchIfNeeded() async {
        guard !isFetchingCandidates, !isRemoteExhausted else { return }
        try? await fetchMoreCandidates()
    }

    // MARK: - Scoring & Re-Ranking

    /// Re-evaluates predicted scores for all queued candidates and re-sorts upcoming cards.
    /// To preserve UI stability, the cards currently visible in the stack (top 2 cards) are kept in place.
    private func rescoreAndRerankCandidates() {
        guard !candidatePool.isEmpty else { return }

        let sContext = sessionTracker.makeContextVector()

        for i in 0..<candidatePool.count {
            let hItem = globalBackbone.forward(input: candidatePool[i].itemFeatureVector)
            var input = [Float]()
            input.reserveCapacity(56)
            input.append(contentsOf: hItem)
            input.append(contentsOf: sContext)

            candidatePool[i].predictedScore = personalHead.predictProbability(input: input)
        }

        // Pin the first 2 cards (currently visible in the UI deck) so they don't shift under the user.
        // Re-rank all upcoming cards [2...] descending by predicted score.
        let pinCount = min(2, candidatePool.count)
        let pinned = Array(candidatePool.prefix(pinCount))
        let upcoming = Array(candidatePool.dropFirst(pinCount))

        let sortedUpcoming = upcoming.sorted { $0.predictedScore > $1.predictedScore }
        candidatePool = pinned + sortedUpcoming
    }

    // MARK: - Remote Ingestion & Candidate Hydration

    private func fetchMoreCandidates() async throws {
        guard !isFetchingCandidates, !isRemoteExhausted else { return }
        isFetchingCandidates = true

        do {
            let result = try await fetchDeckUseCase.execute(page: currentPage, excludingIDs: excludedIDs)
            let sContext = sessionTracker.makeContextVector()

            var newCandidates: [CandidateCard] = []
            for media in result.items where !excludedIDs.contains(media.id) {
                let itemVector = MovieFeatureExtractor.extractItemVector(from: media)
                let hItem = globalBackbone.forward(input: itemVector)

                var input = [Float]()
                input.reserveCapacity(56)
                input.append(contentsOf: hItem)
                input.append(contentsOf: sContext)

                let score = personalHead.predictProbability(input: input)
                newCandidates.append(CandidateCard(
                    media: media,
                    itemFeatureVector: itemVector,
                    predictedScore: score
                ))
            }

            // Sort incoming candidates by predicted score
            newCandidates.sort { $0.predictedScore > $1.predictedScore }

            candidatePool.append(contentsOf: newCandidates)
            currentPage += 1
            isRemoteExhausted = result.isLastPage
            isFetchingCandidates = false

            // If still empty and not exhausted, fetch next page
            if candidatePool.isEmpty && !isRemoteExhausted {
                try await fetchMoreCandidates()
            }
        } catch {
            isFetchingCandidates = false
            throw error
        }
    }

    private func warmStartFromRecentInteractions() {
        let recents = localInteractionSource.loadRecentInteractions(limit: 15)
        for interaction in recents {
            personalHead.trainStep(
                input: interaction.combinedInputVector,
                label: interaction.label,
                lossWeight: interaction.lossWeight * 0.5 // Damped replay weight
            )
        }
    }

    // MARK: - FederatedClientProtocol Boundary

    func exportSharedBackboneDeltas() async -> FederatedWeightDelta {
        return globalBackbone.exportFederatedDelta()
    }

    func applyAggregatedBackboneWeights(weights: [Float], biases: [Float]) async {
        globalBackbone.applyAggregatedWeights(weights: weights, biases: biases)
        rescoreAndRerankCandidates()
    }

    func resetAccumulatedDeltas() async {
        globalBackbone.resetAccumulatedDeltas()
    }
}
