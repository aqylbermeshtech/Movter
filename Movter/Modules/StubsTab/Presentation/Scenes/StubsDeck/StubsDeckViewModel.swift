//
//  StubsDeckViewModel.swift
//  Movter
//

import Combine
import UIKit

@MainActor
final class StubsDeckViewModel: ObservableObject {
    static let maxStackedStubs = 4

    @Published private(set) var reviews: [Review] = []
    @Published private(set) var hasLoaded = false

    private let fetchStubsUseCase: FetchStubsUseCase
    private let fetchArtworkUseCase: FetchStubArtworkUseCase
    private weak var coordinator: StubsCoordinator?

    var stackedReviews: [Review] {
        Array(reviews.prefix(Self.maxStackedStubs))
    }

    init(
        fetchStubsUseCase: FetchStubsUseCase = DefaultFetchStubsUseCase(),
        fetchArtworkUseCase: FetchStubArtworkUseCase = DefaultFetchStubArtworkUseCase(),
        coordinator: StubsCoordinator? = nil
    ) {
        self.fetchStubsUseCase = fetchStubsUseCase
        self.fetchArtworkUseCase = fetchArtworkUseCase
        self.coordinator = coordinator
    }

    func loadStubs() {
        Task {
            do {
                reviews = try await fetchStubsUseCase.execute()
            } catch {
                reviews = []
            }
            hasLoaded = true
        }
    }

    func loadArtwork(for review: Review) async -> (poster: UIImage?, logo: UIImage?) {
        let artwork = await fetchArtworkUseCase.execute(for: review)
        async let poster = loadImage(from: artwork.posterURL)
        async let logo = loadImage(from: artwork.logoURL)
        return (await poster, await logo)
    }

    func didTapStack() {
        coordinator?.showAllStubs()
    }

    private func loadImage(from url: URL?) async -> UIImage? {
        guard let url else { return nil }
        return await withCheckedContinuation { continuation in
            ImageLoader.load(url: url) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
