//
//  GenreProvider.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

struct GenreListResponse: Codable {
    struct Genre: Codable {
        let id: Int
        let name: String
    }
    let genres: [Genre]
}

final class GenreProvider {

    static let shared = GenreProvider()

    private let service: MediaFetching

    init(service: MediaFetching = TMDBService.shared) {
        self.service = service
    }

    private var cache: [MediaType: [Int: String]] = [:]
    private var inFlight: [MediaType: [([Int: String]) -> Void]] = [:]
    private let queue = DispatchQueue(label: "GenreProvider", attributes: .concurrent)

    func primaryGenreName(for ids: [Int]?, type: MediaType, completion: @escaping (String?) -> Void) {
        guard let ids = ids, !ids.isEmpty else {
            completion(nil)
            return
        }
        table(type: type) { table in
            completion(ids.compactMap { table[$0] }.first)
        }
    }

    private func table(type: MediaType, completion: @escaping ([Int: String]) -> Void) {
        if let cached = queue.sync(execute: { cache[type] }) {
            completion(cached)
            return
        }

        var shouldFetch = false
        queue.sync(flags: .barrier) {
            if inFlight[type] == nil {
                inFlight[type] = []
                shouldFetch = true
            }
            inFlight[type]?.append(completion)
        }
        guard shouldFetch else { return }

        service.fetchGenres(type: type) { [weak self] genres in
            guard let self = self else { return }
            let table = Dictionary(uniqueKeysWithValues: (genres ?? []).map { ($0.id, $0.name) })

            var waiting: [([Int: String]) -> Void] = []
            self.queue.sync(flags: .barrier) {
                if !table.isEmpty { self.cache[type] = table }
                waiting = self.inFlight[type] ?? []
                self.inFlight[type] = nil
            }
            waiting.forEach { $0(table) }
        }
    }
}
