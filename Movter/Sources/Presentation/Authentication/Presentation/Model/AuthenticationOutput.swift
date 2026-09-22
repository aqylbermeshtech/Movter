//
//  AuthenticationOutput.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation
//import MovterDomain


struct AuthenticationOutput {
    let onNavigateToOTP: (OTPMethod, String) -> Void
    let onNavigateToCountryList: (@escaping (Country) -> Void) -> Void
    let onNavigateToMainScreen: (UserModel) -> Void
    let onNavigateToRoleSelection: ((UserModel) -> Void)?
    let onAuthenticationCompleted: ((UserModel) -> Void)?
    let onSkipAuthentication: () -> Void
    let onGoBack: (() -> Void)?
    let onOpenPrivacyPolicy: (URL) -> Void
    let onSocialAuthNeedsOnboarding: ((SocialAuthPrefill?) -> Void)?
}
