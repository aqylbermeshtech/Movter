//
//  LocalJSONFileStore.swift
//  MovterStorage
//
//  Created by Nurtore on 13.11.2026.
//

import Foundation

/// Thread-safe, user-scoped JSON file store in the app's Documents directory.
public final class LocalJSONFileStore {

    private let userIDProvider: () -> String?
    private let queue: DispatchQueue

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public init(
        queueLabel: String,
        userIDProvider: @escaping () -> String? = { nil }
    ) {
        self.queue = DispatchQueue(label: queueLabel)
        self.userIDProvider = userIDProvider
    }

    private func fileURL(for prefix: String) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let userID = userIDProvider() ?? "local"
        return documents.appendingPathComponent("\(prefix)-\(userID).json")
    }

    public func loadArray<T: Decodable>(prefix: String) throws -> [T] {
        try queue.sync {
            let url = fileURL(for: prefix)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }
            let data = try Data(contentsOf: url)
            return try Self.decoder.decode([T].self, from: data)
        }
    }

    public func saveArray<T: Encodable>(_ items: [T], prefix: String) throws {
        try queue.sync {
            let url = fileURL(for: prefix)
            let data = try Self.encoder.encode(items)
            try data.write(to: url, options: .atomic)
        }
    }
}

