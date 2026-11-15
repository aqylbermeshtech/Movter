//
//  LibraryCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol LibraryCoordinator: AnyObject {}

@MainActor
final class DefaultLibraryCoordinator: LibraryCoordinator {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
}
