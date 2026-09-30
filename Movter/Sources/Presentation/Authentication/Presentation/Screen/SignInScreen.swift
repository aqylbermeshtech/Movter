//
//  SignInScreen.swift
//  Movter
//
//  Created by Nurtore on 30.09.2026.
//

import SwiftUI
//import MovterUI

struct SignInScreen: View {
    @ObservedObject var viewModel: SignInViewModel
    let output: AuthenticationOutput
    @FocusState private var isInputFocused: Bool
    
    var body:some View {
        GeometryReader { geometry in
            ZStack {
                Color.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        isInputFocused = false
                    }
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        CloseButton(style: .registration) {
                            viewModel.openMenu()
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    
                    Text(LocalizedString.Auth.welcome)
                        .font(Typography.authTitle)
                        .foregroundColor(.onBackground)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.xxxxl)
                    
                    VStack(spacing: Spacing.md) {
                        EmailInputField(
                            text: viewModel.email,
                            isValid: viewModel.isEmailValid,
                            onTextChange: { newEmail in
                                viewModel.setEmail(newEmail)
                            },
                            onValidationChange: { isValid in
                                viewModel.setEmailValid(isValid)
                            })
                                .focused($isInputFocused)
                            
                        VStack(spacing: Spacing.md) {
                            ContinueButton(
                                title: LocalizedString.Auth.getCode
                            ) {
                                viewModel.handleContinue()
                            }
                            policyLinkButton
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)
                    
                    Spacer()
                    
                    SocialLoginButtons(
                        onAppleSignIn: {
                            viewModel.signInWithApple()
                        },
                        onGoogleSignIn: {
                            viewModel.signInWithGoogle()
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .loader(isPresented: $viewModel.isLoading)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onViewAppear()
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
    
    private var policyLinkButton: some View {
        Button(action: { viewModel.handlePolicyTap() }) {
            Text(attributedPolicyText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
    }
    
    private var attributedPolicyText: AttributedString {
        var result = AttributedString(LocalizedString.Policy.text)
        result.font = Typography.policyText
        result.foregroundColor = Color.textSecondary
        
        var boldPart = AttributedString(LocalizedString.Policy.privacy)
        boldPart.font = Typography.policyLink
        boldPart.foregroundColor = Color.onBackground
        
        result.append(boldPart)
        
        return result
    }
}
