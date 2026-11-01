//
//  LoginViewModel.swift
//  Movter
//

import Foundation

@MainActor
final class LoginViewModel {
    private let loginUseCase: LoginUseCase
    private weak var coordinator: AuthCoordinator?

    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var isLoading: Bool = false {
        didSet { onLoadingChanged?(isLoading) }
    }

    init(
        loginUseCase: LoginUseCase,
        coordinator: AuthCoordinator? = nil
    ) {
        self.loginUseCase = loginUseCase
        self.coordinator = coordinator
    }

    func logIn(email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let credentials = LoginCredentials(email: email, password: password)
            _ = try await loginUseCase.execute(credentials: credentials)
            coordinator?.didAuthenticateSuccessfully()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func showSignUp() {
        coordinator?.showSignUp()
    }
}

