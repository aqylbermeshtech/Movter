//
//  AuthViewFactory.swift
//  Movter
//

import UIKit

@MainActor
enum AuthViewFactory {
    static func makeLogin(coordinator: AuthCoordinator) -> UIViewController {
        let dataSource = FirebaseAuthRemoteDataSource()
        let repository = DefaultAuthRepository(dataSource: dataSource)
        let loginUseCase = DefaultLoginUseCase(repository: repository)
        let viewModel = LoginViewModel(loginUseCase: loginUseCase, coordinator: coordinator)
        return LoginViewController(viewModel: viewModel)
    }

    static func makeSignUp(coordinator: AuthCoordinator) -> UIViewController {
        let dataSource = FirebaseAuthRemoteDataSource()
        let repository = DefaultAuthRepository(dataSource: dataSource)
        let signUpUseCase = DefaultSignUpUseCase(repository: repository)
        let viewModel = SignUpViewModel(signUpUseCase: signUpUseCase, coordinator: coordinator)
        return SignUpViewController(viewModel: viewModel)
    }
}

