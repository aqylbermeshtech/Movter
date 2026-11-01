//
//  CastCrewViewController.swift
//  Movter
//
//  Created by Nurtore on 08.09.2026.
//

import UIKit

@MainActor
final class CastCrewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let viewModel: CastCrewViewModel

    init(viewModel: CastCrewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.separatorColor = .hairline
        table.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 16)
        table.dataSource = self
        table.delegate = self
        table.register(CreditCell.self, forCellReuseIdentifier: CreditCell.identifier)
        table.rowHeight = CreditCell.rowHeight
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var emptyView: UIView = {
        let label = UILabel()
        label.text = "No cast or crew details are available for this title."
        label.font = .secondaryBody
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let view = UIView()
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        title = "Cast & Crew"
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
    }

    private func setupLayout() {
        if viewModel.isEmpty {
            view.addSubview(emptyView)
            emptyView.frame = view.bounds
            emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return
        }

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Table view

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CreditCell.identifier, for: indexPath) as? CreditCell,
              let row = viewModel.row(inSection: indexPath.section, at: indexPath.row) else {
            return UITableViewCell()
        }
        cell.configure(with: row)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = viewModel.title(forSection: section) else { return nil }

        let container = UIView()
        container.backgroundColor = .canvas

        let label = UILabel()
        label.text = title
        label.font = .groupHeader
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = viewModel.row(inSection: indexPath.section, at: indexPath.row) else { return }
        viewModel.showActorDetails(actorId: row.personID, name: row.name)
    }
}

