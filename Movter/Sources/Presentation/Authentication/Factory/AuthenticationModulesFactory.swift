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
            output: output,
            signInUseCase: useCaseBuilder.makeSignInUseCase(),
            getLegalTermsUseCase: useCaseBuilder.makeGetLegalTermsUseCase(),
            googleSignInUseCase: useCaseBuilder.makeGoogleSignInUseCase(),
            appleSignInUseCase: useCaseBuilder.makeAppleSignInUseCase(),
            googleSignInManager: googleManager,
            appleSignInManager: appleManager,
            getProfileMeUseCase: useCaseBuilder.makeGetProfileMeUseCase()
        )
        return UIHostingController(rootView: SignInScreen(viewModel: viewModel, output: output))
    }
}
