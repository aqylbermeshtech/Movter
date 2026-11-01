//
//  GetCurrentUserUseCase.swift
//  Movter
//

import Foundation

protocol GetCurrentUserUseCase {
    func execute() -> AuthUser?
}

final class DefaultGetCurrentUserUseCase: GetCurrentUserUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute() -> AuthUser? {
        repository.currentSessionUser
    }
}

