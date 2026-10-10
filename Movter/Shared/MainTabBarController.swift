//
//  MainTabBarController.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import UIKit

final class MainTabBarController: UIViewController {
    struct Tab {
        let title: String
        let symbol: String
        let navigationController: UINavigationController
        let root: TabActionProviding
    }

    static let barBottomInset: CGFloat = 8
    static var contentClearance: CGFloat { CustomTabBarView.preferredHeight + barBottomInset }

    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    private var tabs: [Tab] = []
    private var customBar: CustomTabBarView?
    private let contentContainer = UIView()
    private(set) var selectedIndex = 0

    func setTabs(_ tabs: [Tab]) {
        self.tabs = tabs
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        setupCustomBar()
        setupContentContainer()
        installChildren()
    }

    private func setupCustomBar() {
        let bar = CustomTabBarView(tabs: tabs.map {
            .init(
                title: $0.title,
                systemImage: $0.symbol,
                actionSymbol: $0.root.tabActionSymbol,
                actionLabel: $0.root.tabActionLabel
            )
        })
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        customBar = bar

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.barBottomInset),
            bar.heightAnchor.constraint(equalToConstant: CustomTabBarView.preferredHeight)
        ])

        bar.onTabSelected = { [weak self] index in
            self?.selectTab(at: index)
        }
        bar.onActionTapped = { [weak self] in
            self?.performCurrentTabAction()
        }
    }

    private func setupContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        guard let customBar = customBar else { return }
        view.insertSubview(contentContainer, belowSubview: customBar)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private var selectedChild: UINavigationController? {
        tabs[safe: selectedIndex]?.navigationController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedChild?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectedChild?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedChild?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectedChild?.endAppearanceTransition()
    }

    private func installChildren() {
        for (index, tab) in tabs.enumerated() {
            let child = tab.navigationController
            addChild(child)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(child.view)
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                child.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
                child.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
                child.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
            ])
            child.didMove(toParent: self)
            child.view.isHidden = index != selectedIndex
        }
    }

    private func selectTab(at index: Int) {
        guard tabs.indices.contains(index), index != selectedIndex else { return }
        let outgoing = tabs[selectedIndex].navigationController
        let incoming = tabs[index].navigationController

        outgoing.beginAppearanceTransition(false, animated: false)
        incoming.beginAppearanceTransition(true, animated: false)

        outgoing.view.isHidden = true
        incoming.view.isHidden = false

        outgoing.endAppearanceTransition()
        incoming.endAppearanceTransition()

        selectedIndex = index
    }
    private func performCurrentTabAction() {
        guard presentedViewController == nil else { return }
        tabs[safe: selectedIndex]?.root.performTabAction()
    }
}
