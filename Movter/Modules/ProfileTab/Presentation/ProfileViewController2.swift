//
//  ProfileViewController2.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import UIKit

@MainActor
final class ProfileViewController2: UIViewController {

    // MARK: - Dependencies

    private let viewModel: ProfileViewModel2
    private var loadingTask: Task<Void, Never>?

    // MARK: - UI

    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(
        style: .large
    )
    private let retryButton = UIButton(type: .system)

    // MARK: - Initialization

    init(viewModel: ProfileViewModel2) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindViewModel()
        loadProfile()
    }

    deinit {
        loadingTask?.cancel()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Profile"

        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.textAlignment = .center

        emailLabel.font = .preferredFont(forTextStyle: .body)
        emailLabel.textAlignment = .center

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.addTarget(
            self,
            action: #selector(didTapRetry),
            for: .touchUpInside
        )

        let stackView = UIStackView(arrangedSubviews: [
            activityIndicator,
            nameLabel,
            emailLabel,
            statusLabel,
            retryButton
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            stackView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        loadingTask?.cancel()

        loadingTask = Task { [weak self, viewModel] in
            await viewModel.loadProfile()
        }
    }

    @objc
    private func didTapRetry() {
        loadProfile()
    }

    // MARK: - Rendering

    private func render(_ state: ProfileViewState) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            nameLabel.isHidden = true
            emailLabel.isHidden = true
            statusLabel.text = nil
            retryButton.isHidden = true

        case .loaded(let user):
            activityIndicator.stopAnimating()
            nameLabel.isHidden = false
            emailLabel.isHidden = false
            statusLabel.text = nil
            retryButton.isHidden = true

            nameLabel.text = user.name
            emailLabel.text = user.email

        case .failed(let message):
            activityIndicator.stopAnimating()
            nameLabel.isHidden = true
            emailLabel.isHidden = true
            statusLabel.text = message
            retryButton.isHidden = false
        }
    }
}
