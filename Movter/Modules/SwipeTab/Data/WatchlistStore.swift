//
//  WatchlistStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

protocol WatchlistStoring: AnyObject {
    // MARK: - Modern Async APIs
    func fetchAll() async throws -> [WatchlistItem]
    func save(_ item: WatchlistItem) async throws
    func delete(_ itemID: UUID) async throws

    // MARK: - Backward-Compatible Completion APIs
    func fetchAll(completion: @escaping (Result<[WatchlistItem], Error>) -> Void)
    func save(_ item: WatchlistItem, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(_ itemID: UUID, completion: @escaping (Result<Void, Error>) -> Void)
}

enum WatchlistStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(listType: .watchlist)
    }
}

enum WatchedFilmsStoreFactory {
    static func makeStore() -> WatchlistStoring {
        LocalWatchlistStore(listType: .watched)
    }
}

final class LocalWatchlistStore: WatchlistStoring {

    private let listType: WatchlistPresentationType
    private let repository: WatchlistRepository

    init(
        listType: WatchlistPresentationType = .watchlist,
        repository: WatchlistRepository = DefaultWatchlistRepository()
    ) {
        self.listType = listType
        self.repository = repository
    }

    convenience init(listName: String) {
        let type: WatchlistPresentationType = (listName == "watched") ? .watched : .watchlist
        self.init(listType: type)
    }

    // MARK: - Modern Async APIs

    func fetchAll() async throws -> [WatchlistItem] {
        try await repository.fetchAll(list: listType)
    }

    func save(_ item: WatchlistItem) async throws {
        try await repository.save(item, to: listType)
    }

    func delete(_ itemID: UUID) async throws {
        try await repository.delete(id: itemID, from: listType)
    }

    // MARK: - Backward-Compatible Completion APIs

    func fetchAll(completion: @escaping (Result<[WatchlistItem], Error>) -> Void) {
        Task {
            do {
                let items = try await repository.fetchAll(list: listType)
                DispatchQueue.main.async { completion(.success(items)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func save(_ item: WatchlistItem, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await repository.save(item, to: listType)
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func delete(_ itemID: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await repository.delete(id: itemID, from: listType)
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
