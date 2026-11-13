//
//  MainTabBarController.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import SwiftUI
import UIKit

final class MainTabBarController: UITabBarController {
    struct Tab {
        let title: String
        let symbol: String
        let navigationController: UINavigationController
        let root: UIViewController?

        init(
            title: String,
            symbol: String,
            navigationController: UINavigationController,
            root: UIViewController? = nil
        ) {
            self.title = title
            self.symbol = symbol
            self.navigationController = navigationController
            self.root = root
        }
    }

    static let barBottomInset: CGFloat = 8
    static var contentClearance: CGFloat { CustomTabBarView.preferredHeight + barBottomInset }

    private var tabEntries: [Tab] = []
    private let selectionModel = TabBarSelectionModel()
    private var barHostingController: UIHostingController<CustomTabBarView>?

    override var selectedIndex: Int {
        didSet {
            if selectionModel.selectedIndex != selectedIndex {
                selectionModel.selectedIndex = selectedIndex
            }
        }
    }

    func setTabs(_ tabs: [Tab]) {
        self.tabEntries = tabs
        for (index, tab) in tabs.enumerated() {
            tab.navigationController.tabBarItem = UITabBarItem(
                title: tab.title,
                image: UIImage(systemName: tab.symbol),
                tag: index
            )
        }
        viewControllers = tabs.map(\.navigationController)
        if isViewLoaded {
            setupCustomBar()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        isTabBarHidden = true
        tabBar.isHidden = true
        setupCustomBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.isHidden = true
        if let barView = barHostingController?.view {
            view.bringSubviewToFront(barView)
        }
    }

    private func setupCustomBar() {
        if let existing = barHostingController {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
            barHostingController = nil
        }

        guard !tabEntries.isEmpty else { return }

        let rootView = CustomTabBarView(
            tabs: tabEntries.map {
                .init(
                    title: $0.title,
                    systemImage: $0.symbol
                )
            },
            model: selectionModel,
            onTabSelected: { [weak self] index in
                self?.selectTab(at: index)
            },
            onSearchTapped: { [weak self] in
                self?.performSearchAction()
            }
        )

        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.barBottomInset),
            hosting.view.heightAnchor.constraint(equalToConstant: CustomTabBarView.preferredHeight)
        ])
        hosting.didMove(toParent: self)
        barHostingController = hosting
    }

    private func selectTab(at index: Int) {
        guard tabEntries.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
    }

    private func performSearchAction() {
        guard presentedViewController == nil else { return }
        guard let nav = selectedViewController as? UINavigationController else { return }

        if let presenter = nav.topViewController as? SearchPresenting {
            presenter.presentSearch()
            return
        }

        let overlay = SearchViewFactory.makeSearchOverlay { [weak nav] term in
            let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 2, let nav = nav else { return }
            let resultsVC = SearchViewFactory.makeMovieGrid(source: .search(trimmed), title: "“\(trimmed)”")
            nav.pushViewController(resultsVC, animated: true)
        }
        overlay.modalPresentationStyle = .fullScreen
        present(overlay, animated: true)
    }
}
