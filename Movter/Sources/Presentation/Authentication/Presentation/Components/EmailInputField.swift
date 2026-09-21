//
//  EmailInputField.swift
//  Movter
//
//  Created by Nurtore on 21.09.2026.
//

import SwiftUI
//import MovterUI


public struct EmailInputField: View {
    private enum Constants {
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 33
    }
    
    private let text: String
    private let isValid: Bool
    private let onTextChange: (String) -> Void
    private let onValidationChange: (Bool) -> Void
    
    @State private var internalText: String
    
    public init(text: String, isValid: Bool, onTextChange: @escaping (String) -> Void, onValidationChange: @escaping (Bool) -> Void) {
        self.text = text
        self.isValid = isValid
        self.onTextChange = onTextChange
        self.onValidationChange = onValidationChange
        self._internalText = State(initialValue: text)
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            if internalText.isEmpty {
                Text(LocalizedString.Auth.emailPlaceholder)
                    .font(Typography.inputText)
                    .foregroundColor(Color.textPlaceholderInactive)
                    .padding(.horizontal, Spacing.md)
            }
            
            TextField("", text: $internalText)
                .font(Typography.inputText)
                .foregroundColor(.textPrimary)
                .keyboardType(.asciiCapable)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disableAutocorrection(true)
                .padding(.horizontal, Spacing.md)
                .onChange(of: internalText) { newValue in
                    let normalized = EmailFormatter.normalize(newValue)
                    
                    if normalized != internalText {
                        internalText = normalized
                    }
                    
                    onTextChange(normalized)
                    
                    let isValidEmail = EmailFormatter.isValid(normalized)
                    onValidationChange(isValidEmail)
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
}
