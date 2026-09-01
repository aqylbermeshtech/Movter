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
        service: MediaFetching = NetworkService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.service = service
        self.monitor = monitor
    }

    /// Only when the feed is both empty and unfetchable — an offline placeholder over
    /// content the user is already reading would be worse than saying nothing.
    var showsOfflinePlaceholder: Bool { !monitor.isOnline && mediaContent.isEmpty }

    var onOfflineChange: (() -> Void)?
    var onUpdate: (([Media]) -> Void)?

    private(set) var mediaContent: [Media] = []
    private(set) var selectedGenre: MovieGenre = .all

    func retry() {
        fetchContent(genre: selectedGenre)
    }

    /// Refills the feed once a connection returns, if it never loaded.
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
            // Requests can resolve out of order. If the user has already picked another
            // chip, this response is for a genre nobody's looking at anymore — apply it
            // and it clobbers the current row with the wrong films.
            guard self.selectedGenre == genre else { return }
            self.mediaContent = page?.items ?? []
            self.onUpdate?(self.mediaContent)
        }
    }
}
