//
//  ProfileViewController.swift
//  Movter
//

import UIKit

@MainActor
final class ProfileViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: ProfileViewModel
    private let coordinator: (any ProfileCoordinator)?

    // MARK: - UI Components

    private let headerView = ProfileHeaderView()
    private var loadingTask: Task<Void, Never>?

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.contentInsetAdjustmentBehavior = .always
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Initialization

    init(
        viewModel: ProfileViewModel,
        coordinator: (any ProfileCoordinator)? = nil
    ) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(
        watchlistStore: WatchlistStoring = WatchlistStoreFactory.makeStore(),
        watchedStore: WatchlistStoring = WatchedFilmsStoreFactory.makeStore(),
        reviewStore: ReviewStoring = ReviewStoreFactory.makeStore()
    ) {
        let authDataSource = FirebaseAuthProfileDataSource()
        let profileRepository = DefaultProfileRepository(dataSource: authDataSource)
        let getProfileUseCase = DefaultGetProfileUseCase(repository: profileRepository)
        let signOutUseCase = DefaultSignOutUseCase(repository: profileRepository)
        let changeThemeUseCase = DefaultChangeThemeUseCase()

        let statsRepository = DefaultProfileStatsRepository(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )
        let getProfileStatsUseCase = DefaultGetProfileStatsUseCase(repository: statsRepository)

        let viewModel = ProfileViewModel(
            getProfileUseCase: getProfileUseCase,
            getProfileStatsUseCase: getProfileStatsUseCase,
            signOutUseCase: signOutUseCase,
            changeThemeUseCase: changeThemeUseCase
        )

        let coordinator = DefaultProfileCoordinator(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )

        self.init(viewModel: viewModel, coordinator: coordinator)
        coordinator.viewController = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        loadingTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        setupNavigationBar()
        setupTableView()
        setupHeaderView()
        setupLoadingIndicator()
        bindViewModel()
        loadProfileData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingTask?.cancel()
        loadingTask = Task { [viewModel] in
            await viewModel.reloadStatsOnly()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navigationItem.title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }

    // MARK: - Layout & Views

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 1)
        tableView.tableHeaderView = headerView
    }

    private func setupLoadingIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView, tableView.bounds.width > 0 else { return }

        let height = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard abs(header.frame.height - height) > 0.5 else { return }
        header.frame.size = CGSize(width: tableView.bounds.width, height: height)
        tableView.tableHeaderView = header
    }

    // MARK: - Bindings & Actions

    private func bindViewModel() {
        headerView.statsView.onSelect = { [weak self] stat in
            guard let self else { return }
            switch stat {
            case .watched:   self.showWatched()
            case .reviews:   self.showReviews()
            case .watchlist: self.showWatchlist()
            }
        }

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onNavigationRequired = { [weak self] type in
            guard let self else { return }
            switch type {
            case .reviews:
                self.showReviews()
            case .watchlist:
                self.showWatchlist()
            case .editProfile:
                self.showEditProfile()
            case .notifications:
                self.showNotifications()
            case .privacyPolicy:
                self.showPrivacyPolicy()
            case .changeTheme:
                self.showThemeSelectionAlert()
            case .logout:
                self.confirmLogout()
            }
        }
    }

    private func loadProfileData() {
        loadingTask?.cancel()
        loadingTask = Task { [viewModel] in
            await viewModel.loadProfile()
        }
    }

    private func render(_ state: ProfileViewState) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            tableView.alpha = 0.5
        case .loaded(let user):
            activityIndicator.stopAnimating()
            tableView.alpha = 1.0
            headerView.configure(with: user)
            sizeHeaderToFit()
            tableView.reloadData()
        case .failed(let message):
            activityIndicator.stopAnimating()
            tableView.alpha = 1.0
            presentAlert(title: "Error loading profile", message: message)
        }
    }

    // MARK: - Navigation Delegations to Coordinator

    private func showReviews() {
        coordinator?.showReviews()
    }

    private func showWatched() {
        coordinator?.showWatched()
    }

    private func showWatchlist() {
        coordinator?.showWatchlist()
    }

    private func showEditProfile() {
        coordinator?.showEditProfile { [weak self] in
            self?.loadProfileData()
        }
    }

    private func showNotifications() {
        coordinator?.showNotifications()
    }

    private func showPrivacyPolicy() {
        coordinator?.showPrivacyPolicy(url: ProfileViewModel.privacyPolicyURL)
    }

    private func confirmLogout() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "You'll need to sign in again to get back to your profile.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        Task { [weak self, viewModel, coordinator] in
            do {
                try await viewModel.signOut()
                coordinator?.showLogin()
            } catch {
                self?.presentAlert(title: "Couldn't log out", message: error.localizedDescription)
            }
        }
    }

    private func showThemeSelectionAlert() {
        let alert = UIAlertController(
            title: "App Theme",
            message: "Automatic follows your device's appearance",
            preferredStyle: .actionSheet
        )

        for theme in AppTheme.allCases {
            alert.addAction(UIAlertAction(title: theme.displayName, style: .default) { [weak self] _ in
                guard let self else { return }
                self.viewModel.changeTheme(to: theme)
                self.tableView.reloadData()
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentCentred(alert)
    }

    private func presentCentred(_ alert: UIAlertController) {
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[safe: section]?.options.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[safe: section]?.header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let option = viewModel.option(at: indexPath) else { return cell }

        let isDestructive = option.type == .logout
        let tint: UIColor = isDestructive ? .destructive : .textPrimary

        var content = option.detail == nil
            ? cell.defaultContentConfiguration()
            : UIListContentConfiguration.valueCell()
        content.text = option.title
        content.textProperties.color = tint
        content.secondaryText = option.detail
        content.secondaryTextProperties.color = .textSecondary
        content.image = UIImage(systemName: option.iconName)
        content.imageProperties.tintColor = tint
        cell.contentConfiguration = content

        cell.backgroundColor = .surface
        cell.accessoryType = isDestructive ? .none : .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectOption(at: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .textSecondary
        header.textLabel?.font = .tableSectionHeader
    }
}

// MARK: - Tab action

extension ProfileViewController: TabActionProviding {

    var tabActionSymbol: String { "pencil" }
    var tabActionLabel: String { "Edit profile" }
    func performTabAction() {
        showEditProfile()
    }
}
