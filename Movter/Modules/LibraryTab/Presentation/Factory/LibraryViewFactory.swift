//
//  LibraryViewFactory.swift
//  Movter
//

import UIKit

@MainActor
enum LibraryViewFactory {

    static func makeLibrary(
        coordinator: LibraryCoordinator? = nil
    ) -> UIViewController {
        LibraryViewController(coordinator: coordinator)
    }
}
