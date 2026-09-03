//
//  MainTabBarController.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import UIKit

/// Hosts the app's tabs behind a custom Liquid Glass bar.
///
/// A plain container rather than a `UITabBarController` subclass: even with its system
/// bar hidden, `UITabBarController` keeps reserving bottom safe-area space for it, so a
/// custom bar pinned to the safe area ends up floating well above the screen's edge.
/// Managing the children here sidesteps that entirely.
final class MainTabBarController: UIViewController {

    /// One tab: the nav stack it shows, plus the root screen supplying its action.
    struct Tab {
        let title: String
        let symbol: String
        let navigationController: UINavigationController
        let root: TabActionProviding
    }

    /// The gap between the bar and the bottom safe area.
    static let barBottomInset: CGFloat = 8
    /// What a screen must clear to sit above the floating bar.
    static var contentClearance: CGFloat { CustomTabBarView.preferredHeight + barBottomInset }

    /// The children are all installed at once and swapped by hiding, which UIKit cannot
    /// read as appearing or disappearing. So the forwarding is done by hand below —
    /// without it every tab believes it appeared once at launch and never again, and any
    /// screen that refreshes in `viewWillAppear` serves stale data for the rest of the
    /// session.
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

    /// Full screen, edge to edge. Clearance for the floating bar is applied as
    /// `additionalSafeAreaInsets` on each root screen instead (see `MainTabBarFactory`)
    /// — a nav controller hosted in a frame that stops short of the screen bottom
    /// mispositions its own bars.
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

        // Both sides are told before and after the swap, so the tab being shown gets a
        // real `viewWillAppear` and can refresh whatever changed while it was away.
        outgoing.beginAppearanceTransition(false, animated: false)
        incoming.beginAppearanceTransition(true, animated: false)

        outgoing.view.isHidden = true
        incoming.view.isHidden = false

        outgoing.endAppearanceTransition()
        incoming.endAppearanceTransition()

        selectedIndex = index
    }

    /// The action always belongs to the tab's root screen, even when the user has
    /// navigated deeper — it's the tab's primary action, not the top screen's.
    private func performCurrentTabAction() {
        guard presentedViewController == nil else { return }
        tabs[safe: selectedIndex]?.root.performTabAction()
    }
}
