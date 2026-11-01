//
//  AuthRepository.swift
//  Movter
//

import Foundation

protocol AuthRepository: Sendable {
    var currentSessionUser: AuthUser? { get }
    func logIn(credentials: LoginCredentials) async throws -> AuthUser
    func signUp(credentials: RegisterCredentials) async throws -> AuthUser
    func signOut() throws
}

