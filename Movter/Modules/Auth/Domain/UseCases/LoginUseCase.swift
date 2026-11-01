//
//  LoginUseCase.swift
//  Movter
//

import Foundation
import MovterCore

protocol LoginUseCase {
    func execute(credentials: LoginCredentials) async throws -> AuthUser
}

final class DefaultLoginUseCase: LoginUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(credentials: LoginCredentials) async throws -> AuthUser {
        let email = credentials.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = credentials.password

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }

        guard email.isValidEmail else {
            throw AuthError.invalidEmail
        }

        return try await repository.logIn(credentials: LoginCredentials(email: email, password: password))
    }
}

