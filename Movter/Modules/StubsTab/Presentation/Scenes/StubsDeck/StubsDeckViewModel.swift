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
    @Published private(set) var topFavorites: [FavoriteFilm] = []
    @Published private(set) var hasLoaded = false

    private let fetchStubsUseCase: FetchStubsUseCase
    private let fetchArtworkUseCase: FetchStubArtworkUseCase
    private let fetchTopFavoritesUseCase: FetchTopFavoritesUseCase
    private let updateTopFavoritesUseCase: UpdateTopFavoritesUseCase
    private weak var coordinator: StubsCoordinator?

    var stackedReviews: [Review] {
        Array(reviews.prefix(Self.maxStackedStubs))
    }

    init(
        fetchStubsUseCase: FetchStubsUseCase = DefaultFetchStubsUseCase(),
        fetchArtworkUseCase: FetchStubArtworkUseCase = DefaultFetchStubArtworkUseCase(),
        fetchTopFavoritesUseCase: FetchTopFavoritesUseCase = DefaultFetchTopFavoritesUseCase(),
        updateTopFavoritesUseCase: UpdateTopFavoritesUseCase = DefaultUpdateTopFavoritesUseCase(),
        coordinator: StubsCoordinator? = nil
    ) {
        self.fetchStubsUseCase = fetchStubsUseCase
        self.fetchArtworkUseCase = fetchArtworkUseCase
        self.fetchTopFavoritesUseCase = fetchTopFavoritesUseCase
        self.updateTopFavoritesUseCase = updateTopFavoritesUseCase
        self.coordinator = coordinator
    }

    func loadStubs() {
        Task {
            async let loadedFavorites = fetchTopFavoritesUseCase.execute()
            do {
                reviews = try await fetchStubsUseCase.execute()
            } catch {
                reviews = []
            }
            topFavorites = await loadedFavorites
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

    func addTopFavoriteTapped() {
        guard topFavorites.count < DefaultUpdateTopFavoritesUseCase.maxCount else { return }
        coordinator?.showPickTopFavorite { [weak self] film in
            guard let self else { return }
            Task {
                self.topFavorites = await self.updateTopFavoritesUseCase.add(film)
            }
        }
    }

    func removeTopFavorite(id: Int) {
        Task {
            topFavorites = await updateTopFavoritesUseCase.remove(id: id)
        }
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
