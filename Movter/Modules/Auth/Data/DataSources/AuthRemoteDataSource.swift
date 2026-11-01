//
//  AuthRemoteDataSource.swift
//  Movter
//

import Foundation
import FirebaseAuth

protocol AuthRemoteDataSource: Sendable {
    var currentUser: AuthUser? { get }
    func logIn(email: String, password: String) async throws -> AuthUser
    func signUp(username: String, email: String, password: String) async throws -> AuthUser
    func signOut() throws
}

final class FirebaseAuthRemoteDataSource: AuthRemoteDataSource, @unchecked Sendable {
    private let auth: Auth

    init(auth: Auth = .auth()) {
        self.auth = auth
    }

    var currentUser: AuthUser? {
        guard let user = auth.currentUser, let email = user.email else { return nil }
        return AuthUser(id: user.uid, email: email, displayName: user.displayName)
    }

    func logIn(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            let user = result.user
            guard let userEmail = user.email else {
                throw AuthError.unknown("User has no email associated.")
            }
            return AuthUser(id: user.uid, email: userEmail, displayName: user.displayName)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func signUp(username: String, email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = result.user

            // Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()

            guard let userEmail = user.email else {
                throw AuthError.unknown("User has no email associated.")
            }
            return AuthUser(id: user.uid, email: userEmail, displayName: username)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func signOut() throws {
        try auth.signOut()
    }

    private func mapFirebaseError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }

        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }

        switch code {
        case .wrongPassword, .userNotFound, .invalidEmail, .invalidCredential:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .networkError:
            return .networkError
        case .weakPassword:
            return .weakPassword
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

