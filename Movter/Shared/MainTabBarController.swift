//
//  MainTabBarController.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    struct Tab {
        let title: String
        let symbol: String
        let navigationController: UINavigationController
    }

    private var lastNonSearchTab: UITab?

    func setTabs(_ tabs: [Tab], searchNavigationController: UINavigationController? = nil) {
        var nativeTabs: [UITab] = tabs.enumerated().map { index, tab in
            tab.navigationController.enableInteractivePopGesture()
            return UITab(
                title: tab.title,
                image: UIImage(systemName: tab.symbol),
                identifier: "tab.\(index)"
            ) { _ in
                tab.navigationController
            }
        }

        if let searchNav = searchNavigationController {
            searchNav.enableInteractivePopGesture()
            let searchTab = UISearchTab(
                title: "Search",
                image: UIImage(systemName: "magnifyingglass"),
                identifier: "tab.search"
            ) { _ in
                searchNav
            }
            searchTab.automaticallyActivatesSearch = false
            nativeTabs.append(searchTab)
        }

        self.tabs = nativeTabs
        lastNonSearchTab = nativeTabs.first(where: { !($0 is UISearchTab) })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = .canvas
        tabBar.isHidden = false
        isTabBarHidden = false
    }

    func returnToPreviousTab() {
        guard let target = lastNonSearchTab ?? tabs.first(where: { !($0 is UISearchTab) }) else {
            return
        }
        selectedTab = target
    }

    // MARK: - UITabBarControllerDelegate

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelectTab selectedTab: UITab,
        previousTab: UITab?
    ) {
        if !(selectedTab is UISearchTab) {
            lastNonSearchTab = selectedTab
        } else if let previousTab, !(previousTab is UISearchTab) {
            lastNonSearchTab = previousTab
        }
    }
}
