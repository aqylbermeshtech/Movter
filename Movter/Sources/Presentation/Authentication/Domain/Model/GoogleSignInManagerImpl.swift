//
//  GoogleSignInManagerImpl.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn

final class GoogleSignInManagerImpl: GoogleSignInManagerProtocol {
    weak var presentingViewController: UIViewController?

    @MainActor
    func signIn() async throws -> String {
        guard let presenter = presentingViewController else {
            throw SocialAuthError.noPresenter
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SocialAuthError.missingToken
        }
        return idToken
    }
}

#else

final class GoogleSignInManagerImpl: GoogleSignInManagerProtocol {
    weak var presentingViewController: UIViewController?

    @MainActor
    func signIn() async throws -> String {
        throw SocialAuthError.googleSDKNotConfigured
    }
}

#endif
