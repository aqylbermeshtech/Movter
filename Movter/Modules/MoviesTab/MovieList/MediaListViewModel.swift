//
//  MediaListViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import Foundation

final class MediaListViewModel {

    private let service: MediaFetching
    private let monitor: NetworkMonitoring

    init(
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.service = service
        self.monitor = monitor
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
        service.fetchDiscover(query: genre.query, page: 1) { [weak self] page in
            guard let self = self else { return }
            guard self.selectedGenre == genre else { return }
            self.mediaContent = page?.items ?? []
            self.onUpdate?(self.mediaContent)
        }
    }
}
