//
//  FirebaseAuthProfileDataSource.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthProfileDataSource: ProfileDataSource {
    private let auth: Auth
    
    init(auth: Auth = .auth()) {
        self.auth = auth
    }
    
    func fetchCurrentUser() async throws -> UserDTO {
        guard let user = auth.currentUser else {
            throw ProfileError.unauthenticated
        }
        
        let name: String = {
            if let displayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !displayName.isEmpty {
                return displayName
            }
            if let emailPrefix = user.email?.split(separator: "@").first {
                return String(emailPrefix)
            }
            return "Movie Lover"
        }()
        
        return UserDTO(
            id: user.uid,
            name: name,
            email: user.email ?? "",
            avatarURL: user.photoURL
        )
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else {
            throw ProfileError.unauthenticated
        }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName { changeRequest.displayName = displayName }
        if let photoURL { changeRequest.photoURL = photoURL }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            changeRequest.commitChanges { error in
                if let error {
                    continuation.resume(throwing: ProfileError.updateFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
}
