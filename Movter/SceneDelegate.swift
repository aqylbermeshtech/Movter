//
//  SceneDelegate.swift
//  Movter
//
//  Created by Nurtore on 13.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarFactory.makeTabBar()
        self.window = window
        ThemeManager.shared.apply(to: window)
        window.makeKeyAndVisible()
    }
}

