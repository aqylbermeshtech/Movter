//
//  ErrorAlertModifier.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import SwiftUI

// MARK: - View Extension for Error Alert

public extension View {
    /// Показывает системный алерт с ошибкой. Вызывать на любом экране: `.errorAlert(message: $viewModel.errorMessage)`
    /// - Parameter message: Binding к опциональному сообщению об ошибке. При nil алерт не показывается. При закрытии алерта сбрасывается в nil.
    func errorAlert(message: Binding<String?>) -> some View {
        alert(
            LocalizedString.error,
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button(LocalizedString.ok, role: .cancel) {
                message.wrappedValue = nil
            }
        } message: {
            if let msg = message.wrappedValue {
                Text(msg)
            }
        }
    }
}
