//
//  CountryButton.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import SwiftUI
//import MovterUI
//import MovterDomain

public struct CountryButton: View {
    private enum Constants {
        static let inputFieldHeight: CGFloat = 56
        static let iconButtonSize: CGFloat = 56
        static let smallIconSize: CGFloat = 16
        static let mediumIconSize: CGFloat = 20
        static let cornerRadius: CGFloat = 36
    }
    
    private let selectedCountry: Country?
    private let action: () -> Void
    
    init(selectedCountry: Country? = nil, action: @escaping () -> Void) {
        self.selectedCountry = selectedCountry
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            if let country = selectedCountry {
                HStack(spacing: 0) {
                    Text(country.flag)
                        .font(Typography.emojiMedium)
                    
                    Text(country.dialCode)
                        .font(Typography.inputText)
                        .foregroundColor(.textPrimary)
                        .padding(.leading, Spacing.xs)
                    
                    Spacer()
                        .frame(width: Spacing.sm)
                    
                    ImageAsset.chevron.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.textPlaceholderInactive)
                        .frame(width: Constants.smallIconSize, height: Constants.smallIconSize)
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: Constants.inputFieldHeight)
                .background(Color.inputBackground)
                .cornerRadius(Constants.cornerRadius)
            } else {
                HStack(spacing: Spacing.sm) {
                    ImageAsset.globe.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.textPlaceholderInactive)
                        .frame(width: Constants.mediumIconSize, height: Constants.mediumIconSize)
                    
                    ImageAsset.chevron.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.textPlaceholderInactive)
                        .frame(width: Constants.smallIconSize, height: Constants.smallIconSize)
                }
                .frame(width: Constants.iconButtonSize, height: Constants.iconButtonSize)
                .background(Color.inputBackground)
                .cornerRadius(Constants.cornerRadius)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

