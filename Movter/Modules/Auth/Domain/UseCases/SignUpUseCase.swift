//
//  SignUpUseCase.swift
//  Movter
//

import Foundation
import MovterCore

protocol SignUpUseCase {
    func execute(credentials: RegisterCredentials) async throws -> AuthUser
}

final class DefaultSignUpUseCase: SignUpUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(credentials: RegisterCredentials) async throws -> AuthUser {
        let username = credentials.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = credentials.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = credentials.password

        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.emptyFields
        }

        guard email.isValidEmail else {
            throw AuthError.invalidEmail
        }

        guard password.isStrongPassword else {
            throw AuthError.weakPassword
        }

        return try await repository.signUp(credentials: RegisterCredentials(username: username, email: email, password: password))
    }
}

