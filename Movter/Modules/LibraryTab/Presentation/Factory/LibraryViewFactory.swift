//
//  LibraryViewFactory.swift
//  Movter
//

import UIKit

@MainActor
enum LibraryViewFactory {

    static func makeLibrary(
        coordinator: LibraryCoordinator? = nil,
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository(),
        favoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository()
    ) -> UIViewController {
        let viewModel = LibraryViewModel(
            watchlistRepository: watchlistRepository,
            favoritesRepository: favoritesRepository,
            coordinator: coordinator
        )
        return LibraryViewController(viewModel: viewModel, coordinator: coordinator)
    }
}
