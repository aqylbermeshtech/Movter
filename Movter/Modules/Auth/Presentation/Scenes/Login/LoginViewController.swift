//
//  LoginViewController.swift
//  Movter
//
//  Created by Nurtore on 03.07.2026.
//

import UIKit

class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome Back"
        label.font = .screenTitle
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .surface
        tf.textColor = .textPrimary
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        return tf
    }()

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .surface
        tf.textColor = .textPrimary
        tf.isSecureTextEntry = true
        return tf
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .accent
        button.setTitleColor(.onAccent, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .prominentButton
        return button
    }()

    private let goToSignUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("New here? Create an account", for: .normal)
        button.setTitleColor(.textSecondary, for: .normal)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let repository = DefaultAuthRepository()
        let useCase = DefaultLoginUseCase(repository: repository)
        let vm = LoginViewModel(loginUseCase: useCase)
        self.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        setupLayout()
        setupActions()
        bindViewModel()
    }

    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, loginButton, goToSignUpButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            loginButton.heightAnchor.constraint(equalToConstant: 48),

            activityIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        goToSignUpButton.addTarget(self, action: #selector(didTapGoToSignUp), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.loginButton.isEnabled = !isLoading
            self?.loginButton.setTitle(isLoading ? "" : "Log In", for: .normal)
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }

        viewModel.onError = { [weak self] errorMessage in
            self?.showAlert(message: errorMessage)
        }
    }

    @objc private func didTapLogin() {
        view.endEditing(true)
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        Task {
            await viewModel.logIn(email: email, password: password)
        }
    }

    @objc private func didTapGoToSignUp() {
        viewModel.showSignUp()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

