//
//  WatchlistListViewController.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

/// Every film the user has swiped right on, newest first.
final class WatchlistListViewController: UIViewController {

    private let viewModel: WatchlistListViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(viewModel: WatchlistListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Empty state

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Nothing here yet"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let emptyBodyLabel: UILabel = {
        let label = UILabel()
        label.text = "Swipe right on a film in the Swipe tab and it'll show up here."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyStateView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [emptyTitleLabel, emptyBodyLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        navigationItem.title = "Watchlist"
        navigationController?.navigationBar.prefersLargeTitles = true
        // Explicit rather than inherited: pushed onto a stack whose previous screen
        // opted out, `.automatic` would inherit that and render inline.
        navigationItem.largeTitleDisplayMode = .always

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorColor = .hairline
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.register(WatchlistCell.self, forCellReuseIdentifier: WatchlistCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        viewModel.onChange = { [weak self] in self?.render() }
        viewModel.onError = { [weak self] message in self?.presentError(message) }

        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func render() {
        tableView.reloadData()
        let isEmpty = viewModel.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table

extension WatchlistListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchlistCell.identifier,
            for: indexPath
        ) as! WatchlistCell
        if let item = viewModel.item(at: indexPath) {
            cell.configure(with: item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            guard let self = self else { return }
            self.viewModel.delete(at: indexPath) { success in
                done(success)
                self.render()
            }
        }
        delete.backgroundColor = .destructive
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
