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
        let screen = SignInScreen(viewModel: viewModel, output: output)
        let hostingController = UIHostingController(rootView: screen)
        googleManager.presentingViewController = hostingController
        return hostingController
    }
    
    func makeOTPScreen(
        method: OTPMethod,
        contact: String,
        output: AuthenticationOutput
    ) -> UIHostingController<OTPScreen> {
        let viewModel = OTPViewModel(method: method,
                                     contact: contact,
                                     verifyOTPUseCase: useCaseBuilder.makeVerifyOTPUseCase(),
                                     resendOTPUseCase: useCaseBuilder.makeResendOTPUseCase(),
                                     getProfileMeUseCase: useCaseBuilder.makeGetProfileMeUseCase(),
                                     output: output
        )
        let screen = OTPScreen(viewModel: viewModel)
        return UIHostingController(rootView: screen)
    }
    
    func makeCountryListView(
            onCountrySelected: @escaping (Country) -> Void
    ) -> CountryListScreen {
        let viewModel = CountryListViewModel(
            getGroupedCountriesUseCase: useCaseBuilder.makeGetGroupedCountriesUseCase()
        )
        return CountryListScreen(viewModel: viewModel, onCountrySelected: onCountrySelected)
    }
    
    func makeRoleSelectionScreen(output: RoleSelectionOutput) -> UIHostingController<RoleSelectionScreen> {
        let viewModel = RoleSelectionViewModel(
            submitRoleUseCase: useCaseBuilder.makeSubmitRoleSelectionUseCase(),
            output: output
        )
        let screen = RoleSelectionScreen(viewModel: viewModel)
        return UIHostingController(rootView: screen)
    }
    
    
}
