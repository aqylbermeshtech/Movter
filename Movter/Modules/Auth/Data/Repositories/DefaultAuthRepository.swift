//
//  DefaultAuthRepository.swift
//  Movter
//

import Foundation

final class DefaultAuthRepository: AuthRepository, @unchecked Sendable {
    private let dataSource: AuthRemoteDataSource

    init(dataSource: AuthRemoteDataSource = FirebaseAuthRemoteDataSource()) {
        self.dataSource = dataSource
    }

    var currentSessionUser: AuthUser? {
        dataSource.currentUser
    }

    func logIn(credentials: LoginCredentials) async throws -> AuthUser {
        try await dataSource.logIn(email: credentials.email, password: credentials.password)
    }

    func signUp(credentials: RegisterCredentials) async throws -> AuthUser {
        try await dataSource.signUp(
            username: credentials.username,
            email: credentials.email,
            password: credentials.password
        )
    }

    func signOut() throws {
        try dataSource.signOut()
    }
}

