//
//  StubsViewFactory.swift
//  Movter
//

import UIKit

@MainActor
enum StubsViewFactory {

    static func makeStubsDeck(
        coordinator: StubsCoordinator? = nil,
        repository: StubsRepository = DefaultStubsRepository(),
        favoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository()
    ) -> UIViewController {
        let fetchStubsUseCase = DefaultFetchStubsUseCase(repository: repository)
        let fetchArtworkUseCase = DefaultFetchStubArtworkUseCase(repository: repository)
        let fetchTopFavoritesUseCase = DefaultFetchTopFavoritesUseCase(repository: favoritesRepository)
        let updateTopFavoritesUseCase = DefaultUpdateTopFavoritesUseCase(repository: favoritesRepository)
        let viewModel = StubsDeckViewModel(
            fetchStubsUseCase: fetchStubsUseCase,
            fetchArtworkUseCase: fetchArtworkUseCase,
            fetchTopFavoritesUseCase: fetchTopFavoritesUseCase,
            updateTopFavoritesUseCase: updateTopFavoritesUseCase,
            coordinator: coordinator
        )
        return StubsDeckViewController(viewModel: viewModel, coordinator: coordinator)
    }

    static func makeStubsList(
        coordinator: StubsCoordinator? = nil,
        repository: StubsRepository = DefaultStubsRepository()
    ) -> UIViewController {
        let fetchStubsUseCase = DefaultFetchStubsUseCase(repository: repository)
        let fetchArtworkUseCase = DefaultFetchStubArtworkUseCase(repository: repository)
        let viewModel = StubsListViewModel(
            fetchStubsUseCase: fetchStubsUseCase,
            fetchArtworkUseCase: fetchArtworkUseCase,
            coordinator: coordinator
        )
        return StubsListViewController(viewModel: viewModel, coordinator: coordinator)
    }
}
