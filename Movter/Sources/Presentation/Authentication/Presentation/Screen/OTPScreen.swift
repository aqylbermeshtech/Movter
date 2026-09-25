//
//  OTPScreen.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import SwiftUI
//import MovterUI

struct OTPScreen: View {
    private enum Constants {
        static let containerHeight: CGFloat = 56
        static let contentTopPadding: CGFloat = 132
    }
    
    @ObservedObject var viewModel: OTPViewModel
    
    var body: some View {
        ZStack {
            Color.backgroundCode
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    BackButton {
                        viewModel.onBackButtonTapped()
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                
                otpContent
                    .padding(.top, Constants.contentTopPadding)
                Spacer(minLength: 0)
            }
        }
        .loader(isPresented: $viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
        .alert(LocalizedString.Otp.goBackTitle,
               isPresented: $viewModel.showGoBackConfirmation) {
            Button(LocalizedString.cancel, role:.cancel)
            Button(LocalizedString.Otp.goBackConfirm) {
                viewModel.confirmGoBack()
            }
        } message: {
            Text(LocalizedString.Otp.goBackMessage)
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onViewAppear()
        }
    }
    
    private var otpContent: some View {
        VStack(spacing: Spacing.sm) {
            Text(viewModel.method == .telegram ? LocalizedString.Otp.titleTelegram : LocalizedString.Otp.titleEmail)
                .font(Typography.authTitle)
                .foregroundColor(Color.onSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
            
            Text(viewModel.method == .telegram ? LocalizedString.Otp.subtitleTelegram(viewModel.contact) : LocalizedString.Otp.subtitleEmail(viewModel.contact))
                .font(Typography.otpSubtitle)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
            
            OTPInputView(otpCode: viewModel.otpCode,
                         isError: viewModel.isError { newCode in
                viewModel.setOTPCode(newCode)
            }
        )
            .frame(height: Constants.containerHeight)
            .padding(.horizontal, Spacing.md)
            
            ResendButton(
                canResend: viewModel.canResend,
                remainingSeconds: viewModel.remainingSeconds
            ) {
                viewModel.resendCode()
            }
                .padding(.horizontal, Spacing.md)

            Text(LocalizedString.Otp.attemptsLeft(viewModel.attemptsLeft))
                .font(Typography.policyText)
                .foregroundColor(Color.textSecondary)
                .padding(.top, 0)
        }
    }
}
