//
//  SocialLoginButtons.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import SwiftUI
//import MovterUI

public struct SocialLoginButtons: View {
    private let onAppleSignIn: () -> Void
    private let onGoogleSignIn: () -> Void
    
    public init(onAppleSignIn: @escaping () -> Void = {}, onGoogleSignIn: @escaping () -> Void = {}) {
        self.onAppleSignIn = onAppleSignIn
        self.onGoogleSignIn = onGoogleSignIn
    }
    
    public var body: some View {
        VStack(spacing: Spacing.md) {
            Text(LocalizedString.Auth.orSignInWith)
                .font(Typography.dividerText)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: Spacing.sm) {
                AppleLoginButton(action: onAppleSignIn)
                GoogleLoginButton(action: onGoogleSignIn)
            }
        }
    }
}


struct AppleLoginButton: View {
    private enum Constants {
        static let height: CGFloat = 60
    }
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "apple.logo")
                .font(Typography.medium24)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.height)
                .background(Color.inputBackground)
                .cornerRadius(CornerRadius.sm)
        }
    }
}

struct GoogleLoginButton: View {
    private enum Constants {
            static let height: CGFloat = 60
        }

        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ImageAsset.google.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Spacing.lg, height: Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.height)
                    .background(Color.inputBackground)
                    .cornerRadius(CornerRadius.sm)
            }
        }
}
