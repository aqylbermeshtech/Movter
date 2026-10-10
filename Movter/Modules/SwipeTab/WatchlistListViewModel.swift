//
//  WatchlistListViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

final class WatchlistListViewModel {

    struct Presentation {
        let title: String
        let emptyTitle: String
        let emptyBody: String
        let datePrefix: String
        let removeTitle: String

        static let watchlist = Presentation(
            title: "Watchlist",
            emptyTitle: "Nothing here yet",
            emptyBody: "Swipe right on a film in the Swipe tab and it'll show up here.",
            datePrefix: "Added",
            removeTitle: "Remove"
        )

        static let watched = Presentation(
            title: "Watched",
            emptyTitle: "Nothing watched yet",
            emptyBody: "Mark a film as watched on its page and it'll show up here.",
            datePrefix: "Watched",
            removeTitle: "Unmark"
        )
    }

    let presentation: Presentation

    var onChange: (() -> Void)?
    var onError: ((String) -> Void)?

    private let store: WatchlistStoring
    private(set) var items: [WatchlistItem] = []

    init(store: WatchlistStoring, presentation: Presentation = .watchlist) {
        self.store = store
        self.presentation = presentation
    }

    var isEmpty: Bool { items.isEmpty }

    func load() {
        store.fetchAll { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(items):
                self.items = items
                self.onChange?()
            case let .failure(error):
                self.onError?(error.localizedDescription)
            }
        }
    }

    func item(at indexPath: IndexPath) -> WatchlistItem? {
        items[safe: indexPath.row]
    }

    func delete(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        guard let item = item(at: indexPath) else {
            completion(false)
            return
        }
        items.remove(at: indexPath.row)

        store.delete(item.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                completion(true)
            case let .failure(error):
                self.onError?(error.localizedDescription)
                self.load()
                completion(false)
            }
        }
    }
}
