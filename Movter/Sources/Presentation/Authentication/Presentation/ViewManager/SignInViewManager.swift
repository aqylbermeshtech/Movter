//
//  SignInViewManager.swift
//  Movter
//
//  Created by Nurtore on 30.09.2026.
//

import Foundation
import SwiftUI
import Combine

protocol SignInViewManagerDelegate: AnyObject {
    func onNavigateToOTP(method: OTPMethod, contact: String)
    func onNavigateToCountryList()
}


final class SignInViewManager: ObservableObject {
    weak var delegate: SignInViewManagerDelegate?

    // TODO: вернуть byPhone при добавлении входа по телефону
    @Published var selectedMethod: String = LocalizedString.Auth.byEmail
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var isPhoneValid: Bool = false
    @Published var isEmailValid: Bool = false
    @Published var selectedCountry: Country? = nil

    var isInputFilled: Bool {
        if selectedMethod == LocalizedString.Auth.byPhone {
            return !phoneNumber.isEmpty
        } else {
            return !email.isEmpty
        }
    }

    var isInputValid: Bool {
        if selectedMethod == LocalizedString.Auth.byPhone {
            return isPhoneValid
        } else {
            return isEmailValid
        }
    }

    var isContinueEnabled: Bool {
        return isInputFilled
    }

    func setSelectedMethod(_ method: String) {
        selectedMethod = method
    }

    func setPhoneNumber(_ phone: String) {
        phoneNumber = phone
    }

    func setEmail(_ email: String) {
        self.email = email
    }

    func setPhoneValid(_ isValid: Bool) {
        isPhoneValid = isValid
    }

    func setEmailValid(_ isValid: Bool) {
        isEmailValid = isValid
    }

    func setSelectedCountry(_ country: Country?) {
        selectedCountry = country
    }

    func resetInput() {
        phoneNumber = ""
        email = ""
        isPhoneValid = false
        isEmailValid = false
        selectedCountry = nil
    }
}
