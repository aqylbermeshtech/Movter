//
//  WatchlistLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol WatchlistLocalDataSource: AnyObject {
    func loadItems(listName: String) throws -> [WatchlistItem]
    func saveItems(_ items: [WatchlistItem], listName: String) throws
}

final class LocalFileWatchlistDataSource: WatchlistLocalDataSource {

    private let store: LocalJSONFileStore

    init(userIDProvider: @escaping () -> String? = { nil }) {
        self.store = LocalJSONFileStore(
            queueLabel: "com.nurtore.movter.watchlist.localstorage",
            userIDProvider: userIDProvider
        )
    }

    func loadItems(listName: String) throws -> [WatchlistItem] {
        try store.loadArray(prefix: listName)
    }

    func saveItems(_ items: [WatchlistItem], listName: String) throws {
        try store.saveArray(items, prefix: listName)
    }
}

