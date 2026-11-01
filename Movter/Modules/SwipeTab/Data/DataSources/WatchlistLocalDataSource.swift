//
//  WatchlistLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation
import FirebaseAuth

protocol WatchlistLocalDataSource: AnyObject {
    func loadItems(listName: String) throws -> [WatchlistItem]
    func saveItems(_ items: [WatchlistItem], listName: String) throws
}

final class LocalFileWatchlistDataSource: WatchlistLocalDataSource {

    private let userIDProvider: () -> String?
    private let queue = DispatchQueue(label: "com.nurtore.movter.watchlist.localstorage")

    private func fileURL(for listName: String) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userID = userIDProvider() ?? "local"
        return documents.appendingPathComponent("\(listName)-\(userID).json")
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.userIDProvider = userIDProvider
    }

    func loadItems(listName: String) throws -> [WatchlistItem] {
        try queue.sync {
            let url = fileURL(for: listName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }
            let data = try Data(contentsOf: url)
            return try decoder.decode([WatchlistItem].self, from: data)
        }
    }

    func saveItems(_ items: [WatchlistItem], listName: String) throws {
        try queue.sync {
            let url = fileURL(for: listName)
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
        }
    }
}

