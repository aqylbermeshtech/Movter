//
//  NotificationSettingsViewController.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import UIKit

@MainActor
final class NotificationSettingsViewController: UIViewController {

    private let viewModel: NotificationSettingsViewModel
    private var loadingTask: Task<Void, Never>?

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Initialization

    init(viewModel: NotificationSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let repository = DefaultNotificationPreferencesRepository()
        let getUseCase = DefaultGetNotificationPreferencesUseCase(repository: repository)
        let setUseCase = DefaultSetNotificationPreferenceUseCase(repository: repository)
        let permissionUseCase = DefaultRequestNotificationPermissionUseCase(repository: repository)
        let viewModel = NotificationSettingsViewModel(
            getPreferencesUseCase: getUseCase,
            setPreferenceUseCase: setUseCase,
            permissionUseCase: permissionUseCase
        )
        self.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadingTask?.cancel()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        title = "Notifications"

        setupTableView()
        bindViewModel()

        // The user can change permission in Settings and come back, so re-read on return.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    // MARK: - Setup & Binding

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func refreshData() {
        loadingTask?.cancel()
        loadingTask = Task { [weak self] in
            await self?.viewModel.loadData()
        }
    }

    @objc private func applicationDidBecomeActive() {
        refreshData()
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        viewModel.togglePreference(at: sender.tag, isEnabled: sender.isOn)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension NotificationSettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : viewModel.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "SYSTEM PERMISSION" : "WHAT TO SEND"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        return viewModel.permissionFooterText
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .surface
        cell.selectionStyle = .default
        cell.accessoryView = nil
        cell.accessoryType = .none

        var content = cell.defaultContentConfiguration()
        content.textProperties.color = .textPrimary
        content.secondaryTextProperties.color = .textSecondary

        if indexPath.section == 0 {
            content.text = "Notifications"
            content.secondaryText = viewModel.statusText
            cell.accessoryType = viewModel.isAuthorized ? .checkmark : .disclosureIndicator
            cell.tintColor = .accent
        } else {
            guard viewModel.items.indices.contains(indexPath.row) else { return cell }
            let item = viewModel.items[indexPath.row]
            content.text = item.preference.title
            content.secondaryText = item.preference.subtitle

            let toggle = UISwitch()
            toggle.tag = indexPath.row
            toggle.isOn = item.isEnabled && viewModel.isAuthorized
            toggle.isEnabled = viewModel.isAuthorized
            toggle.onTintColor = .accent
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

            cell.accessoryView = toggle
            cell.selectionStyle = .none
            content.textProperties.color = viewModel.isAuthorized ? .textPrimary : .textSecondary
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .textSecondary
        header.textLabel?.font = .tableSectionHeader
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footer = view as? UITableViewHeaderFooterView else { return }
        footer.textLabel?.textColor = .textSecondary
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }

        Task { [weak self] in
            await self?.viewModel.handlePermissionTap()
        }
    }
}
