//
//  MarkFilmSeenUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol MarkFilmSeenUseCase {
    func execute(tmdbID: Int)
}

final class DefaultMarkFilmSeenUseCase: MarkFilmSeenUseCase {

    private let repository: SeenFilmsRepository

    init(repository: SeenFilmsRepository = DefaultSeenFilmsRepository()) {
        self.repository = repository
    }

    func execute(tmdbID: Int) {
        repository.markSeen(tmdbID: tmdbID)
    }
}

