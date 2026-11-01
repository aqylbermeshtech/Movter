//
//  GetSeenFilmIDsUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol GetSeenFilmIDsUseCase {
    func execute() -> Set<Int>
}

final class DefaultGetSeenFilmIDsUseCase: GetSeenFilmIDsUseCase {

    private let repository: SeenFilmsRepository

    init(repository: SeenFilmsRepository = DefaultSeenFilmsRepository()) {
        self.repository = repository
    }

    func execute() -> Set<Int> {
        repository.fetchSeenIDs()
    }
}

