//
//  PhoneInputField.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import SwiftUI
//import MovterUI
//import MovterDomain

public struct PhoneInputField: View {
    private enum Constants {
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 33
    }
    
    private let text: String
    private let isValid: Bool
    private let selectedCountry: Country?
    private let onTextChange: (String) -> Void
    private let onValidationChange: (Bool) -> Void
    private let onCountryPickerTap: () -> Void
    
    @State private var displayText: String = ""
    
    init(text: String, isValid: Bool, selectedCountry: Country?, onTextChange: @escaping (String) -> Void, onValidationChange: @escaping (Bool) -> Void, onCountryPickerTap: @escaping () -> Void) {
        self.text = text
        self.isValid = isValid
        self.selectedCountry = selectedCountry
        self.onTextChange = onTextChange
        self.onValidationChange = onValidationChange
        self.onCountryPickerTap = onCountryPickerTap
        self._displayText = State(initialValue: PhoneFormatter.formatKazakhstanPhone(text))
    }
    
    public var body: some View {
        HStack(spacing: Spacing.sm) {
            CountryButton(selectedCountry: selectedCountry, action: { onCountryPickerTap() } )
            
            ZStack(alignment: .leading) {
                if displayText.isEmpty {
                    Text(LocalizedString.Auth.phonePlaceholder)
                        .font(Typography.inputText)
                        .foregroundColor(Color.textPlaceholderInactive)
                        .padding(.horizontal, Spacing.md)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $displayText)
                    .font(Typography.inputText)
                    .foregroundColor(.textPrimary)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, Spacing.md)
                    .onChange(of: displayText) { newValue in
                        let formatted = PhoneFormatter.formatKazakhstanPhone(newValue)
                        
                        if formatted != displayText {
                            displayText = formatted
                        }
                        
                        let digits = PhoneFormatter.extractDigits(formatted)
                        onTextChange(digits)
                        
                        let isValidPhone = PhoneFormatter.isValid(digits)
                        onValidationChange(isValidPhone)
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.height)
            .background(Color.inputBackground)
            .cornerRadius(Constants.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Color.inputBorder, lineWidth: 1)
            )
        }
        .frame(height: Constants.height)
    }
}
