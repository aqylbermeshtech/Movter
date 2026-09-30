//
//  SignInViewModel.swift
//  Movter
//
//  Created by Nurtore on 30.09.2026.
//

import Foundation
import Combine
//imrot MovterUI
//import MovterDomain

final class SignInViewModel: ObservableObject {
    private let signInUseCase: SignInUseCaseProtocol
    private let output: AuthenticationOutput
    private let viewManager = SignInViewManager()
    private let getLegalTermsUseCase: GetLegalTermsUseCaseProtocol
    private let googleSignInUseCase: GoogleSignInUseCaseProtocol
    private let appleSignInUseCase: AppleSignInUseCaseProtocol
    let googleSignInManager: GoogleSignInManagerImpl
    let appleSignInManager: AppleSignInManagerImpl
    private let getProfileMeUseCase: GetProfileMeUseCaseProtocol
    
    var email: String { viewManager.email }
    var isEmailValid: Bool { viewManager.isEmailValid }
    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private var cachedPolicyURL: URL?
    private var isPolicyLoading = false
    
    
    init(output: AuthenticationOutput, signInUseCase: SignInUseCaseProtocol, getLegalTermsUseCase: GetLegalTermsUseCaseProtocol, googleSignInUseCase: GoogleSignInUseCaseProtocol, appleSignInUseCase: AppleSignInUseCaseProtocol, googleSignInManager: GoogleSignInManagerImpl, appleSignInManager: AppleSignInManagerImpl, getProfileMeUseCase: GetProfileMeUseCaseProtocol) {
        self.output = output
        self.signInUseCase = signInUseCase
        self.getLegalTermsUseCase = getLegalTermsUseCase
        self.googleSignInUseCase = googleSignInUseCase
        self.appleSignInUseCase = appleSignInUseCase
        self.googleSignInManager = googleSignInManager
        self.appleSignInManager = appleSignInManager
        self.getProfileMeUseCase = getProfileMeUseCase
    }
    
    func openMenu() {
        output.onSkipAuthentication()
    }
    
    func onViewAppear() {
        viewManager.delegate = self
        prefetchPolicyURL()
    }
    
    func setEmail(_ email: String) {
        viewManager.setEmail(email)
    }
    
    func setEmailValid(_ isValid: Bool) {
        viewManager.setEmailValid(isValid)
    }
    
    func handleContinue() {
        guard viewManager.isInputValid else {
            errorMessage = LocalizedString.Error.invalidEmail
            return
        }
        signInWithEmail()
    }
    
    func handlePolicyTap() {
        if let url = cachedPolicyURL {
            output.onOpenPrivacyPolicy(url)
            return
        }
        fetchPolicy(presentWhenReady: true)
    }
    
    func signInWithApple() {
        guard !isLoading else { return }
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let credential = try await appleSignInManager.signIn()
                let result = try await appleSignInUseCase.execute(idToken: credential.idToken, name: credential.name)
                handleSocialAuthResult(result)
            } catch SocialAuthError.cancelled {
                // user dismissed the dialog — silent
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func signInWithGoogle() {
        guard !isLoading else { return }
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            do {
                let idToken = try await googleSignInManager.signIn()
                let result = try await googleSignInUseCase.execute(idToken: idToken)
                handleSocialAuthResult(result)
            } catch SocialAuthError.cancelled {
                // user dismissed the dialog — silent
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func prefetchPolicyURL() {
        guard cachedPolicyURL == nil else { return }
        fetchPolicy(presentWhenReady: false)
    }
    
    private func fetchPolicy(presentWhenReady: Bool) {
        guard !isPolicyLoading else { return }
        isPolicyLoading = true
        Task { @MainActor in
            defer { isPolicyLoading = false }
            do {
                let urlString = try await getLegalTermsUseCase.execute()
                guard let url = URL(string: urlString) else { return }
                cachedPolicyURL = url
                if presentWhenReady {
                    output.onOpenPrivacyPolicy(url)
                }
            } catch {
                // Silently fail — policy link won't be functional
            }
        }
    }
    
    private func signInWithEmail() {
        guard !isLoading else { return }
        SocialAuthNameStore.clear()
        let credentials = AuthCredentials(
            method: .email(email),
            contact: email
        )
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let success = try await signInUseCase.execute(credentials: credentials.toDTO())
                if success {
                    output.onNavigateToOTP(.email, email)
                }
            } catch {
                errorMessage = error.localizedDescription.isEmpty ? LocalizedString.genericError : error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func handleSocialAuthResult(_ result: SocialAuthResult) {
        switch result.status {
        case .authenticated:
            SocialAuthNameStore.clear()
            loadProfileAndNavigateToMain()
        case .onboardingRequired:
            SocialAuthNameStore.save(fullName: result.prefill?.name)
            Task {
                if let token = MovterPushNotificationRuntime.lastFCMToken {
                    await PushDeviceTokenRegistrar.registerWithBackendIfAuthenticated(fcmToken: token)
                }
            }
            let user = UserModel(
                id: "",
                name: result.prefill?.name ?? "",
                avatarUrl: result.prefill?.photo,
                userType: nil
            )
            if let onRoleSelection = output.onNavigateToRoleSelection {
                onRoleSelection(user)
            } else if let onOnboarding = output.onSocialAuthNeedsOnboarding {
                onOnboarding(result.prefill)
            } else {
                output.onNavigateToMainScreen(user)
            }
        }
    }
    
    private func loadProfileAndNavigateToMain() {
        Task { @MainActor in
            do {
                if let profile = try await getProfileMeUseCase.execute() {
                    let user = UserModel(
                        id: profile.userId ?? "",
                        name: profile.name ?? "",
                        avatarUrl: profile.photoUrl,
                        userType: profile.userType
                    )
                    output.onNavigateToMainScreen(user)
                } else {
                    output.onNavigateToMainScreen(UserModel(id: "", name: "", avatarUrl: nil, userType: nil))
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func selectCountry(_ country: Country) {
        viewManager.setSelectedCountry(country)
    }
}


extension SignInViewModel: SignInViewManagerDelegate {
    func onNavigateToOTP(method: OTPMethod, contact: String) {
        output.onNavigateToOTP(method, contact)
    }

    func onNavigateToCountryList() {
        output.onNavigateToCountryList { [weak self] country in
            self?.selectCountry(country)
        }
    }
}
