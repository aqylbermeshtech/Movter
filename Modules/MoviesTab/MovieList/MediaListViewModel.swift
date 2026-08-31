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
    var showsOfflinePlaceholder: Bool { !monitor.isOnline && !hasContent }

    private var hasContent: Bool {
        currentType == .articles ? !articleContent.isEmpty : !mediaContent.isEmpty
    }

    var onOfflineChange: (() -> Void)?

    func retry() {
        fetchContent(type: currentType)
    }

    /// Refills the feed once a connection returns, if it never loaded.
    func connectivityDidChange() {
        if monitor.isOnline, !hasContent {
            fetchContent(type: currentType)
        } else {
            onOfflineChange?()
        }
    }

    private(set) var mediaContent: [Media] = []
    private(set) var articleContent: [Article] = []
    var onUpdate: ((TrendingResult) -> Void)?
    private(set) var currentType: ContentType = .movies

    func fetchContent(type: ContentType) {
        self.currentType = type
        guard monitor.isOnline else {
            onOfflineChange?()
            return
        }
        onOfflineChange?()
        service.fetchTrendingContent(type: type) { [weak self] result in
            guard let self = self else { return }
            // Requests can resolve out of order. If the user has already switched
            // tabs, this response is for a type nobody's looking at anymore — apply
            // it and it clobbers the current tab with stale content.
            guard self.currentType == type else { return }
            switch result {
            case .media(let mediaList):
                self.mediaContent = mediaList
                self.onUpdate?(.media(mediaList))
            case .articles(let articleList):
                self.articleContent = articleList
                self.onUpdate?(.articles(articleList))
            }
        }
    }
    
    func getUrl(for article: Article) -> URL? {
        return URL(string: article.webUrl)
    }
}
