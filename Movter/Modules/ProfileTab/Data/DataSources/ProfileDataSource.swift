//
//  ProfileDataSource.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

protocol ProfileDataSource {
    func fetchCurrentUser() async throws -> UserDTO
    func updateProfile(displayName: String?, photoURL: URL?) async throws
    func signOut() throws
}
