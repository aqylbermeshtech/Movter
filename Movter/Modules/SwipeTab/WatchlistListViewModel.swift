//
//  WatchlistListViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

final class WatchlistListViewModel {

    var onChange: (() -> Void)?
    var onError: ((String) -> Void)?

    private let store: WatchlistStoring
    private(set) var items: [WatchlistItem] = []

    init(store: WatchlistStoring) {
        self.store = store
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
        // Optimistic: a failed write reloads from disk and puts the row back.
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
