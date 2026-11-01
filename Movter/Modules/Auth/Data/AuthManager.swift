//
//  AuthManager.swift
//  Movter
//
//  Created by Nurtore on 03.07.2026.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()
    private let repository: AuthRepository

    init(repository: AuthRepository = DefaultAuthRepository()) {
        self.repository = repository
    }

    func signUp(withUserRequest request: RegisterUserRequest, completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                _ = try await repository.signUp(credentials: request)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }

    func logIn(withUserRequest request: LoginUserRequest, completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                _ = try await repository.logIn(credentials: request)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
}

