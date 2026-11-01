//
//  SignUpViewController.swift
//  Movter
//
//  Created by Nurtore on 03.07.2026.
//

import UIKit

class SignUpViewController: UIViewController {
    private let viewModel: SignUpViewModel

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .screenTitle
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .surface
        tf.textColor = .textPrimary
        tf.autocapitalizationType = .words
        return tf
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
        tf.textContentType = .newPassword
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .accent
        button.setTitleColor(.onAccent, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .prominentButton
        return button
    }()

    private let goToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Already have an account? Log In", for: .normal)
        button.setTitleColor(.textSecondary, for: .normal)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let repository = DefaultAuthRepository()
        let useCase = DefaultSignUpUseCase(repository: repository)
        let vm = SignUpViewModel(signUpUseCase: useCase)
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
        let stackView = UIStackView(arrangedSubviews: [titleLabel, usernameTextField, emailTextField, passwordTextField, signUpButton, goToLoginButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            signUpButton.heightAnchor.constraint(equalToConstant: 48),

            activityIndicator.centerXAnchor.constraint(equalTo: signUpButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: signUpButton.centerYAnchor)
        ])
    }

    private func setupActions() {
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
        goToLoginButton.addTarget(self, action: #selector(didTapGoToLogin), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            self?.signUpButton.isEnabled = !isLoading
            self?.signUpButton.setTitle(isLoading ? "" : "Sign Up", for: .normal)
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

    @objc private func didTapSignUp() {
        view.endEditing(true)
        let username = usernameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        Task {
            await viewModel.signUp(username: username, email: email, password: password)
        }
    }

    @objc private func didTapGoToLogin() {
        viewModel.dismiss()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

