//
//  ProfileViewFactory.swift
//  Movter
//

import UIKit

enum ProfileViewFactory {

    @MainActor
    static func make(
        watchlistStore: WatchlistStoring = WatchlistStoreFactory.makeStore(),
        watchedStore: WatchlistStoring = WatchedFilmsStoreFactory.makeStore(),
        reviewStore: ReviewStoring = ReviewStoreFactory.makeStore()
    ) -> UIViewController {
        let authDataSource = FirebaseAuthProfileDataSource()
        let profileRepository = DefaultProfileRepository(dataSource: authDataSource)
        let getProfileUseCase = DefaultGetProfileUseCase(repository: profileRepository)
        let signOutUseCase = DefaultSignOutUseCase(repository: profileRepository)
        let changeThemeUseCase = DefaultChangeThemeUseCase()

        let statsRepository = DefaultProfileStatsRepository(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )
        let getProfileStatsUseCase = DefaultGetProfileStatsUseCase(repository: statsRepository)

        let viewModel = ProfileViewModel(
            getProfileUseCase: getProfileUseCase,
            getProfileStatsUseCase: getProfileStatsUseCase,
            signOutUseCase: signOutUseCase,
            changeThemeUseCase: changeThemeUseCase
        )

        let coordinator = DefaultProfileCoordinator(
            watchlistStore: watchlistStore,
            watchedStore: watchedStore,
            reviewStore: reviewStore
        )

        let viewController = ProfileViewController(
            viewModel: viewModel,
            coordinator: coordinator
        )
        coordinator.viewController = viewController

        return viewController
    }
}
