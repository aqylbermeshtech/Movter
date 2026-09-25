//
//  OTPViewManager.swift
//  Movter
//
//  Created by Nurtore on 25.09.2026.
//

import Foundation
import SwiftUI
import Combine

protocol OTPViewManagerDelegate: AnyObject {
    func onNavigateToMainScreen()
}

final class OTPViewManager: ObservableObject {
    weak var delegate: OTPViewManagerDelegate?

    @Published var otpCode: String = "" { didSet { isError = false } }
    @Published var isError: Bool = false
    @Published var remainingSeconds: Int = 58
    @Published var canResend: Bool = false
    @Published var attemptsLeft: Int = 3

    func setOTPCode(_ code: String) {
        otpCode = code
    }

    func setError(_ hasError: Bool) {
        isError = hasError
        if hasError {
            otpCode = ""
        }
    }

    func setRemainingSeconds(_ seconds: Int) {
        remainingSeconds = seconds
    }

    func setCanResend(_ canResend: Bool) {
        self.canResend = canResend
    }

    func setAttemptsLeft(_ attempts: Int) {
        attemptsLeft = attempts
    }

    func resetCode() {
        otpCode = ""
        isError = false
    }
}


