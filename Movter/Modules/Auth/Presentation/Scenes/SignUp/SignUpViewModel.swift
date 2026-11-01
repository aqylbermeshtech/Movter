//
//  SignUpViewModel.swift
//  Movter
//

import Foundation

@MainActor
final class SignUpViewModel {
    private let signUpUseCase: SignUpUseCase
    private weak var coordinator: AuthCoordinator?

    var onLoadingChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var isLoading: Bool = false {
        didSet { onLoadingChanged?(isLoading) }
    }

    init(
        signUpUseCase: SignUpUseCase,
        coordinator: AuthCoordinator? = nil
    ) {
        self.signUpUseCase = signUpUseCase
        self.coordinator = coordinator
    }

    func signUp(username: String, email: String, password: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let credentials = RegisterCredentials(username: username, email: email, password: password)
            _ = try await signUpUseCase.execute(credentials: credentials)
            coordinator?.didAuthenticateSuccessfully()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func dismiss() {
        coordinator?.dismissSignUp()
    }
}

