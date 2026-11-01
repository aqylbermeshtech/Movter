//
//  AuthCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol AuthCoordinator: AnyObject {
    func showSignUp()
    func dismissSignUp()
    func didAuthenticateSuccessfully()
}

@MainActor
final class DefaultAuthCoordinator: AuthCoordinator {
    weak var navigationController: UINavigationController?
    weak var window: UIWindow?
    private let makeTabBar: @MainActor () -> UIViewController

    init(
        window: UIWindow? = nil,
        navigationController: UINavigationController? = nil,
        makeTabBar: @escaping @MainActor () -> UIViewController = { MainTabBarFactory.makeTabBar() }
    ) {
        self.window = window
        self.navigationController = navigationController
        self.makeTabBar = makeTabBar
    }

    func showSignUp() {
        let signUpVC = AuthViewFactory.makeSignUp(coordinator: self)
        signUpVC.modalPresentationStyle = .fullScreen
        let presenter = navigationController?.topViewController ?? navigationController
        presenter?.present(signUpVC, animated: true)
    }

    func dismissSignUp() {
        let presenter = navigationController?.topViewController ?? navigationController
        if let presented = presenter?.presentedViewController {
            presented.dismiss(animated: true)
        } else {
            presenter?.dismiss(animated: true)
        }
    }

    func didAuthenticateSuccessfully() {
        guard let targetWindow = window ?? navigationController?.view.window else { return }
        targetWindow.rootViewController = makeTabBar()
        UIView.transition(with: targetWindow, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}

