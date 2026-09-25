//
//  ResendButton.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import SwiftUI

public struct ResendButton: View {
    private enum Constants {
        static let textSpacing: CGFloat = Spacing.xxs
        static let height: CGFloat = 60
        static let previewSpacing: CGFloat = 20
        static let cornerRadius: CGFloat = 15
    }

    private let canResend: Bool
    private let remainingSeconds: Int
    private let action: () -> Void

    @State private var isPressed = false

    public init(
        canResend: Bool,
        remainingSeconds: Int,
        action: @escaping () -> Void
    ) {
        self.canResend = canResend
        self.remainingSeconds = remainingSeconds
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard canResend else { return }

            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            action()
        }) {
            VStack(spacing: Constants.textSpacing) {
                Text(LocalizedString.Otp.resend)
                    .font(Typography.resendButtonTitle)
                    .foregroundColor(textColor)

                if !canResend {
                    Text(LocalizedString.Otp.resendInSeconds(remainingSeconds))
                        .font(Typography.resendButtonSubtitle)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.height)
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .shadow(
                color: canResend ? Color.shadow : Color.clear,
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: Spacing.animationVeryFast), value: isPressed)
        }
        .disabled(!canResend)
        .buttonStyle(ResendButtonStyle(isPressed: $isPressed))
    }

    private var textColor: Color {
        canResend ? .white : Color.buttonTextDisabled
    }

    private var backgroundColor: Color {
        canResend ? Color.buttonPrimary : Color.buttonPrimary.opacity(0.6)
    }
}

private struct ResendButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

#Preview("Can Resend") {
    VStack(spacing: 20) {
        ResendButton(
            canResend: true,
            remainingSeconds: 0
        ) {}
        .padding(.horizontal, Spacing.md)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundCode)
}

#Preview("Waiting - 58 seconds") {
    VStack(spacing: 20) {
        ResendButton(
            canResend: false,
            remainingSeconds: 58
        ) {}
        .padding(.horizontal, Spacing.md)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundCode)
}

//#Preview("Waiting - 5 seconds") {
//    VStack(spacing: 20) {
//        ResendButton(
//            canResend: false,
//            remainingSeconds: 5
//        ) {}
//        .padding(.horizontal, Spacing.md)
//    }
//    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .background(Color.backgroundCode)
//}
