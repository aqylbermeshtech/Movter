//
//  AuthRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public protocol AuthRepositoryProtocol {
    func signIn(credentials: AuthCredentialsDTO) async throws -> Bool
    func logout() async throws -> Bool
    func deleteAccount() async throws -> DeleteAccountOutcome
    func switchRole(toRole role: String) async throws -> SwitchRoleResultDTO
    func getAuthMe() async throws -> AuthMeDataDTO?
    func signInWithGoogle(idToken: String) async throws -> SocialAuthResult
    func signInWithApple(idToken: String, name: String?) async throws -> SocialAuthResult
}
