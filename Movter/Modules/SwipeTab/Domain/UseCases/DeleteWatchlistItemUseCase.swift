//
//  DeleteWatchlistItemUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol DeleteWatchlistItemUseCase {
    func execute(id: UUID, from list: WatchlistPresentationType) async throws
}

final class DefaultDeleteWatchlistItemUseCase: DeleteWatchlistItemUseCase {

    private let repository: WatchlistRepository

    init(repository: WatchlistRepository = DefaultWatchlistRepository()) {
        self.repository = repository
    }

    func execute(id: UUID, from list: WatchlistPresentationType) async throws {
        try await repository.delete(id: id, from: list)
    }
}

