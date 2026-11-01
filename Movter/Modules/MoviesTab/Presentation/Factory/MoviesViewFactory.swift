//
//  MoviesViewFactory.swift
//  Movter
//

import UIKit

@MainActor
enum MoviesViewFactory {

    static func makeMovieList(coordinator: MoviesCoordinator) -> MediaListViewController {
        let moviesRepository = DefaultMoviesRepository()
        let fetchDiscoverUseCase = DefaultFetchDiscoverMediaUseCase(repository: moviesRepository)
        let viewModel = MediaListViewModel(
            fetchDiscoverUseCase: fetchDiscoverUseCase,
            coordinator: coordinator
        )
        return MediaListViewController(viewModel: viewModel, coordinator: coordinator)
    }

    static func makeMovieDetails(media: Media, coordinator: MoviesCoordinator) -> MediaDetailsViewController {
        let detailsRepository = DefaultMovieDetailsRepository()
        let creditsUseCase = DefaultGetMovieCreditsUseCase(repository: detailsRepository)
        let similarUseCase = DefaultGetSimilarMoviesUseCase(repository: detailsRepository)
        let trailerUseCase = DefaultGetTrailerUseCase(repository: detailsRepository)
        let watchStatusUseCase = DefaultGetMediaWatchStatusUseCase()
        let toggleWatchlistUseCase = DefaultToggleWatchlistUseCase()
        let toggleWatchedUseCase = DefaultToggleWatchedUseCase()
        let getReviewUseCase = DefaultGetUserReviewForMovieUseCase()
        let saveReviewUseCase = DefaultSaveUserReviewUseCase()

        let viewModel = MediaDetailsViewModel(
            media: media,
            creditsUseCase: creditsUseCase,
            similarUseCase: similarUseCase,
            trailerUseCase: trailerUseCase,
            detailsRepository: detailsRepository,
            watchStatusUseCase: watchStatusUseCase,
            toggleWatchlistUseCase: toggleWatchlistUseCase,
            toggleWatchedUseCase: toggleWatchedUseCase,
            getReviewUseCase: getReviewUseCase,
            saveReviewUseCase: saveReviewUseCase,
            coordinator: coordinator
        )
        return MediaDetailsViewController(viewModel: viewModel, coordinator: coordinator)
    }

    static func makeCastCrew(
        mediaTitle: String,
        cast: [Actor],
        crew: [CrewMember],
        coordinator: MoviesCoordinator
    ) -> CastCrewViewController {
        let viewModel = CastCrewViewModel(
            mediaTitle: mediaTitle,
            cast: cast,
            crew: crew,
            coordinator: coordinator
        )
        return CastCrewViewController(viewModel: viewModel)
    }

    static func makeActorDetails(
        actorId: Int,
        name: String,
        coordinator: MoviesCoordinator
    ) -> ActorViewController {
        let personRepository = DefaultPersonRepository()
        let detailsUseCase = DefaultGetPersonDetailsUseCase(repository: personRepository)
        let creditsUseCase = DefaultGetPersonCreditsUseCase(repository: personRepository)
        let viewModel = ActorViewModel(
            actorId: actorId,
            name: name,
            detailsUseCase: detailsUseCase,
            creditsUseCase: creditsUseCase,
            coordinator: coordinator
        )
        return ActorViewController(viewModel: viewModel, coordinator: coordinator)
    }

    static func makeTrailer(
        filmTitle: String,
        request: URLRequest,
        coordinator: MoviesCoordinator
    ) -> TrailerViewController {
        TrailerViewController(filmTitle: filmTitle, request: request)
    }
}
