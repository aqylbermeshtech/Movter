//
//  SearchMoviesController.swift
//  Movter
//
//  Created by Nurtore on 01.05.2026.
//

import UIKit

final class SearchMoviesController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let viewModel = SearchMoviesViewModel()

    /// Raised by the tab bar's action button rather than sitting in the navigation bar,
    /// so the browse list gets the full screen until the user asks to search.
    private let searchController = UISearchController(searchResultsController: nil)
    private let chevronImage = UIImage(systemName: "chevron.right")
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .clear
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.estimatedRowHeight = 44.0
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        setupNavigationBar()
        setupSearch()
        setupUI()
    }
    
    //MARK: - UI
    private func setupNavigationBar() {
        navigationItem.title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }
    
    private func setupSearch() {
        searchController.searchBar.placeholder = "Search films"
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchBar.searchTextField.textColor = .textPrimary
        searchController.searchBar.tintColor = .textPrimary
        searchController.obscuresBackgroundDuringPresentation = false
        // Not presented directly — see `performTabAction()`. UISearchController also
        // rejects any `modalPresentationStyle` outside .custom / .popover / .formSheet,
        // throwing at assignment time, so that's left alone too.
    }

    private func showResults(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        // Don't stack duplicate result screens on top of one another.
        if let top = navigationController?.topViewController, top !== self { return }

        let resultsVC = MovieGridViewController(source: .search(trimmed), title: "“\(trimmed)”")
        // Ends the search session; `didDismissSearchController` then takes the search
        // bar back out of the navigation bar.
        searchController.isActive = false
        navigationController?.pushViewController(resultsVC, animated: true)
    }

    private func setupUI() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(in: section)
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        header.textLabel?.textColor = .textPrimary
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = viewModel.item(at: indexPath)
        cell.textLabel?.textColor = .textPrimary
        cell.backgroundColor = .surface
        
        let accessoryView = UIImageView(image: chevronImage)
        accessoryView.tintColor = .textSecondary
        cell.accessoryView = accessoryView
        
        if cell.selectedBackgroundView == nil {
            let selectionView = UIView()
            selectionView.backgroundColor = .hairline
            cell.selectedBackgroundView = selectionView
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let target = viewModel.handleSelection(at: indexPath) else { return }

        switch target {
        case .subcategory(let title, let items):
            let subCategoryVC = SubcategoryViewController(title: title, items: items)
            navigationController?.pushViewController(subCategoryVC, animated: true)
            
        case .infoAction(let title, let description):
            print("Лог действия [\(title)]: \(description)")

        }
    }
}

extension SearchMoviesController: UISearchBarDelegate, UISearchControllerDelegate {

    /// Submit-driven rather than debounced-as-you-type: pushing results mid-keystroke
    /// would collapse the search session out from under the user.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        showResults(for: searchBar.text ?? "")
    }

    /// The search bar only exists while a search is in progress, so it comes back out
    /// once the session ends and the browse list gets the full screen again.
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.searchController = nil
    }
}

// MARK: - Tab action

extension SearchMoviesController: TabActionProviding {

    var tabActionSymbol: String { "magnifyingglass" }
    var tabActionLabel: String { "Search films" }

    /// Fits the search bar into the navigation bar and starts a search session, rather
    /// than presenting the search controller itself — presented directly it arrives as
    /// a detached panel instead of the standard bar-anchored search.
    func performTabAction() {
        searchController.searchBar.text = nil

        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            // Let the navigation bar lay the search bar out before activating it;
            // activating a search bar that has no frame yet drops the focus.
            navigationController?.navigationBar.setNeedsLayout()
            navigationController?.navigationBar.layoutIfNeeded()
        }

        searchController.isActive = true
        DispatchQueue.main.async { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
    }
}
