//
//  MediaListViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

@MainActor
final class MediaListViewModel {

    private let fetchDiscoverUseCase: FetchDiscoverMediaUseCase
    private let monitor: NetworkMonitoring
    private weak var coordinator: MoviesCoordinator?

    init(
        fetchDiscoverUseCase: FetchDiscoverMediaUseCase = DefaultFetchDiscoverMediaUseCase(),
        monitor: NetworkMonitoring = NetworkMonitor.shared,
        coordinator: MoviesCoordinator? = nil
    ) {
        self.fetchDiscoverUseCase = fetchDiscoverUseCase
        self.monitor = monitor
        self.coordinator = coordinator
    }

    convenience init(
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        let repo = DefaultMoviesRepository(remoteDataSource: TMDBMoviesRemoteDataSource(service: service))
        let useCase = DefaultFetchDiscoverMediaUseCase(repository: repo)
        self.init(fetchDiscoverUseCase: useCase, monitor: monitor, coordinator: nil)
    }

    var showsOfflinePlaceholder: Bool { !monitor.isOnline && mediaContent.isEmpty }

    var onOfflineChange: (() -> Void)?
    var onUpdate: (([Media]) -> Void)?

    private(set) var mediaContent: [Media] = []
    private(set) var selectedGenre: MovieGenre = .all

    func retry() {
        fetchContent(genre: selectedGenre)
    }

    func connectivityDidChange() {
        if monitor.isOnline, mediaContent.isEmpty {
            fetchContent(genre: selectedGenre)
        } else {
            onOfflineChange?()
        }
    }

    func fetchContent(genre: MovieGenre) {
        self.selectedGenre = genre
        mediaContent = []
        guard monitor.isOnline else {
            onOfflineChange?()
            return
        }
        onOfflineChange?()

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let items = try await self.fetchDiscoverUseCase.execute(genre: genre, page: 1)
                guard self.selectedGenre == genre else { return }
                self.mediaContent = items
                self.onUpdate?(self.mediaContent)
            } catch {
                guard self.selectedGenre == genre else { return }
                self.mediaContent = []
                self.onUpdate?([])
            }
        }
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        coordinator?.showMovieDetails(media: media, from: source)
    }

    func showMovieGrid(genre: MovieGenre) {
        coordinator?.showMovieGrid(genre: genre)
    }
}

