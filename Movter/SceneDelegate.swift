//
//  SceneDelegate.swift
//  Movter
//
//  Created by Nurtore on 13.03.2026.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var authCoordinator: AuthCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        if Auth.auth().currentUser != nil {
            window.rootViewController = MainTabBarFactory.makeTabBar()
        } else {
            let coordinator = DefaultAuthCoordinator(window: window)
            let loginVC = AuthViewFactory.makeLogin(coordinator: coordinator)
            let loginNav = UINavigationController(rootViewController: loginVC)
            coordinator.navigationController = loginNav
            self.authCoordinator = coordinator
            window.rootViewController = loginNav
        }
        self.window = window
        ThemeManager.shared.apply(to: window)
        window.makeKeyAndVisible()
    }
}

