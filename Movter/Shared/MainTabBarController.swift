//
//  MainTabBarController.swift
//  Movter
//
//  Created by Nurtore on 22.08.2026.
//

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

    static let contentClearance: CGFloat = 0

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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        tabBar.isHidden = false
        isTabBarHidden = false
    }
}
