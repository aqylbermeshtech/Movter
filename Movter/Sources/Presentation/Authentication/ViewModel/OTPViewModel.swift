//
//  OTPViewModel.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import Foundation
import Combine
//import MovterDomain
//import MovterNetwork
//import MovterUI

final class OTPViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showGoBackConfirmation: Bool = false
    
    private var pendingOTPResult: OTPVerificationResult?
    private var viewManager = OTPViewManager()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    var otpCode: String { viewManager.otpCode }
    var isError: Bool { viewManager.isError }
    var canResend: Bool { viewManager.canResend }
    var remainingSeconds: Int { viewManager.remainingSeconds }
    var attemptsLeft: Int { viewManager.attemptsLeft }
    var hasCodeBeenSent: Bool {
        !viewManager.canResend || viewManager.remainingSeconds > 0
    }
    
    let method: OTPMethod
    let contact: String
    private let output: AuthenticationOutput
    private let verifyOTPUseCase: VerifyOTPUseCaseProtocol
    private let resendOTPUseCase: ResendOTPUseCaseProtocol
    private let getProfileMeUseCase: GetProfileMeUseCaseProtocol
    
    init(method: OTPMethod, contact: String,verifyOTPUseCase: VerifyOTPUseCaseProtocol, resendOTPUseCase: ResendOTPUseCaseProtocol, getProfileMeUseCase: GetProfileMeUseCaseProtocol, output: AuthenticationOutput) {
        self.method = method
        self.contact = contact
        self.output = output
        self.verifyOTPUseCase = verifyOTPUseCase
        self.resendOTPUseCase = resendOTPUseCase
        self.getProfileMeUseCase = getProfileMeUseCase
    }
    
    func onViewAppear() {
        viewManager.delegate = self
    }
    
    private func setupObservers() {
        viewManager.$otpCode
            .sink { [weak self] code in
                guard let self = self else { return }
                self.objectWillChange.send()
                if code.count == 6 {
                    self.verifyCode()
                }
            }
            .store(in: &cancellables)
        
        viewManager.$canResend
            .combineLatest(viewManager.$remainingSeconds, viewManager.$attemptsLeft, viewManager.$isError)
            .sink { [weak self] _, _, _, _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func setOTPCode(_ code: String) {
        viewManager.setOTPCode(code)
    }

    func resendCode() {
        guard viewManager.canResend, viewManager.attemptsLeft > 0 else { return }
        
        viewManager.setAttemptsLeft(viewManager.attemptsLeft - 1)
        viewManager.resetCode()
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let success = try await resendOTPUseCase.execute(method: method.toDTO(), contact: contact)
                if success {
                    startTimer()
                }
            } catch {
                errorMessage = LocalizedString.genericError
            }
            isLoading = false
        }
    }

    func onBackButtonTapped() {
        if hasCodeBeenSent {
            showGoBackConfirmation = true
        } else {
            output.onGoBack?()
        }
    }

    func confirmGoBack() {
        output.onGoBack?()
    }

    private func verifyCode() {
        guard !isLoading else { return }
        isLoading = true
        
        Task { @MainActor in
            await verifyOTPCode()
        }
    }
        
    private func startTimer() {
        viewManager.setRemainingSeconds(58)
        viewManager.setCanResend(false)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.viewManager.remainingSeconds > 0 {
                    self.viewManager.setRemainingSeconds(self.viewManager.remainingSeconds - 1)
                } else {
                    self.viewManager.setCanResend(true)
                    self.timer?.invalidate()
                }
            }
        }
    }

    private func verifyOTPCode() async {
        do {
            let resultDTO = try await verifyOTPUseCase.execute(
                method: method.toDTO(),
                contact: contact,
                code: otpCode
            )
            let result = OTPVerificationResult(dto: resultDTO)
            
            if result.isSuccess {
                if result.isPendingOnboarding {
                    let user = userFromOTPResult(result)
                    await MainActor.run {
                        navigateAfterOTP(result: result, user: user)
                    }
                } else {
                    do {
                        let user = try await loadUserFromProfile()
                        await MainActor.run {
                            navigateAfterOTP(result: result, user: user)
                        }
                    } catch {
                        await MainActor.run {
                            pendingOTPResult = result
                            isLoading = false
                            errorMessage = LocalizedString.genericError
                        }
                    }
                }
            } else {
                await MainActor.run {
                    viewManager.setError(true)
                    errorMessage = LocalizedString.Otp.errorWrongCode
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                viewManager.setError(true)
                errorMessage = LocalizedString.Otp.errorWrongCode
                isLoading = false
            }
        }
    }

    private func navigateAfterOTP(result: OTPVerificationResult, user: UserModel) {
        isLoading = false
        Task {
            if let token = MovterPushNotificationRuntime.lastFCMToken {
                await PushDeviceTokenRegistrar.registerWithBackendIfAuthenticated(fcmToken: token)
            }
        }
        if result.isCompletedOnboarding, let onCompleted = output.onAuthenticationCompleted {
            onCompleted(user)
        } else if let onRoleSelection = output.onNavigateToRoleSelection {
            onRoleSelection(user)
        } else {
            output.onNavigateToMainScreen(user)
        }
    }

    func retryAfterNetworkError() {
        guard let result = pendingOTPResult else { return }
        isLoading = true
        Task { @MainActor in
            do {
                let user = try await loadUserFromProfile()
                navigateAfterOTP(result: result, user: user)
            } catch {
                isLoading = false
                errorMessage = LocalizedString.genericError
            }
        }
    }

    private func userFromOTPResult(_ result: OTPVerificationResult) -> UserModel {
        UserModel(
            id: result.userId ?? "",
            name: "",
            avatarUrl: nil,
            userType: nil
        )
    }

    private func loadUserFromProfile() async throws -> UserModel {
        if let profile = try await getProfileMeUseCase.execute() {
            return UserModel(
                id: profile.userId ?? "",
                name: profile.name ?? "",
                avatarUrl: profile.photoUrl,
                userType: profile.userType
            )
        }
        throw NSError(domain: "OTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
    }

    deinit {
        timer?.invalidate()
    }
}

extension OTPViewModel: OTPViewManagerDelegate {
    func onNavigateToMainScreen() {
        isLoading = true
        Task { @MainActor in
            do {
                let user = try await loadUserFromProfile()
                isLoading = false
                if let onRoleSelection = output.onNavigateToRoleSelection {
                    onRoleSelection(user)
                } else {
                    output.onNavigateToMainScreen(user)
                }
            } catch {
                isLoading = false
                errorMessage = LocalizedString.genericError
            }
        }
    }
}
