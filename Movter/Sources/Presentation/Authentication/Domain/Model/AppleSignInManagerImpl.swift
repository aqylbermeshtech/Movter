//
//  AppleSignInManagerImpl.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import UIKit
import AuthenticationServices

final class AppleSignInManagerImpl: NSObject, AppleSignInManagerProtocol {
    private var continuation: CheckedContinuation<AppleSignInCredential, Error>?

    @MainActor
    func signIn() async throws -> AppleSignInCredential {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AppleSignInManagerImpl: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: SocialAuthError.missingToken)
            continuation = nil
            return
        }
        let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
        let name = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")

        continuation?.resume(returning: AppleSignInCredential(idToken: idToken, name: name))
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError = (error as? ASAuthorizationError)?.code == .canceled
            ? SocialAuthError.cancelled
            : error
        continuation?.resume(throwing: authError)
        continuation = nil
    }
}

extension AppleSignInManagerImpl: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? UIWindow()
    }
}
