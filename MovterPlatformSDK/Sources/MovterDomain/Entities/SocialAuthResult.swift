//
//  SocialAuthResult.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation

public struct SocialAuthResult {
    public enum AuthStatus {
        case authenticated
        case onboardingRequired
    }
    
    public let status: AuthStatus
    public let prefill: SocialAuthPrefill?
    
    public init(status: AuthStatus, prefill: SocialAuthPrefill?) {
        self.status = status
        self.prefill = prefill
    }
}

public struct SocialAuthPrefill {
    public let name: String?
    public let email: String?
    public let photo: String?

    public init(name: String? = nil, email: String? = nil, photo: String? = nil) {
        self.name = name
        self.email = email
        self.photo = photo
    }
}
