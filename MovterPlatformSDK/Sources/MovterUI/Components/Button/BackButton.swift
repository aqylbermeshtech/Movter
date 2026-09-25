//
//  BackButton.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import SwiftUI

public struct BackButton: View {
    private enum Constants {
        static let iconSize: CGFloat = 44
    }
    
    public enum Style {
        case light
        case dark
    }

    private let style: Style
    private let action: () -> Void

    public init(style: Style = .dark, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: onTap) {
            buttonImage
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(LocalizedString.back))
    }

    // MARK: - Computed Properties
    private var buttonImage: Image {
        switch style {
        case .light:
            return ImageAsset.backButton.swiftUIImage
        case .dark:
            return ImageAsset.backButtonOTP.swiftUIImage
        }
    }

    private func onTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        action()
    }
}

#Preview {
    HStack {
        BackButton { }
        Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.backgroundCode)
}
