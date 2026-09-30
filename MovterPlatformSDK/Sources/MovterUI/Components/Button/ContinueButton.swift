//
//  ContinueButton.swift
//  Movter
//
//  Created by Nurtore on 30.09.2026.
//

import SwiftUI

public struct ContinueButton: View {
    public enum Constants {
        static let height: CGFloat = 60
    }
    
    private let title: String
    private let action: () -> Void
    private let isEnabled: Bool
    private let contentHorizontalPadding: CGFloat?
    
    public init(title: String, action: @escaping () -> Void, isEnabled: Bool = true, contentHorizontalPadding: CGFloat? = nil) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.contentHorizontalPadding = contentHorizontalPadding
    }
    
    public var body: some View {
        Button(
            action: {
                guard isEnabled else { return }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                action()
            }) {
                Text(title)
                    .font(Typography.buttonPrimary)
                    .foregroundColor(isEnabled ? .white : .buttonTextDisabled)
                    .padding(.horizontal, contentHorizontalPadding ?? 0)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.height)
                    .background(Color.buttonPrimary.opacity(isEnabled ? 1.0 : 0.6))
                    .cornerRadius(CornerRadius.xl)
                    .shadow(
                        color: Color.shadow,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
    }
    
    
}
