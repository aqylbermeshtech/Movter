//
//  AuthenticationModulesFactory.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import SwiftUI
import UIKit
//import MovterUI
//import MovterDomain

final class AuthenticationModulesFactory {
    private let useCaseBuilder = UseCaseBuilder()
    
    func makeSignInScreen(output: AuthenticationOutput) -> UIHostingController<SignInScreen> {
        let googleManager = GoogleSignInManagerImpl()
        let appleManager = AppleSignInManagerImpl()
        let viewModel = SignInViewModel(
            signInUseCase: useCaseBuilder.makeSignInUseCase(),
            googleSignInUseCase: useCaseBuilder.makeGoogleSignInUseCase(),
            appleSignInUseCase: useCaseBuilder.makeAppleSignInUseCase(),
            getCountryByIdUseCase: useCaseBuilder.makeGetCountryByIdUseCase(),
            getLegalTermsUseCase: useCaseBuilder.makeGetLegalTermsUseCase(),
            getProfileMeUseCase: useCaseBuilder.makeGetProfileMeUseCase(),
            googleSignInManager: googleManager,
            appleSignInManager: appleManager,
            output: output
        )
    }
}
