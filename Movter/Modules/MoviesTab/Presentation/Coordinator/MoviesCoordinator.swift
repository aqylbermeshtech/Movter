//
//  MoviesCoordinator.swift
//  Movter
//

import UIKit

@MainActor
protocol MoviesCoordinator: AnyObject {
    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource)
    func showMovieGrid(genre: MovieGenre)
    func showCastCrew(mediaTitle: String, cast: [Actor], crew: [CrewMember])
    func showActorDetails(actorId: Int, name: String)
    func showTrailer(filmTitle: String, request: URLRequest)
    func dismiss()
}

@MainActor
final class DefaultMoviesCoordinator: MoviesCoordinator {
    weak var navigationController: UINavigationController?
    private let posterTransition: PosterTransitionController

    init(
        navigationController: UINavigationController? = nil,
        posterTransition: PosterTransitionController? = nil
    ) {
        self.navigationController = navigationController
        self.posterTransition = posterTransition ?? PosterTransitionController()
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        let detailVC = MoviesViewFactory.makeMovieDetails(media: media, coordinator: self)
        posterTransition.push(detailVC, for: media, from: source)
    }

    func showMovieGrid(genre: MovieGenre) {
        let gridVC = MovieGridViewController(source: .discover(genre.query), title: genre.sectionTitle)
        navigationController?.pushViewController(gridVC, animated: true)
    }

    func showCastCrew(mediaTitle: String, cast: [Actor], crew: [CrewMember]) {
        let castCrewVC = MoviesViewFactory.makeCastCrew(mediaTitle: mediaTitle, cast: cast, crew: crew, coordinator: self)
        navigationController?.pushViewController(castCrewVC, animated: true)
    }

    func showActorDetails(actorId: Int, name: String) {
        let actorVC = MoviesViewFactory.makeActorDetails(actorId: actorId, name: name, coordinator: self)
        navigationController?.pushViewController(actorVC, animated: true)
    }

    func showTrailer(filmTitle: String, request: URLRequest) {
        let trailerVC = MoviesViewFactory.makeTrailer(filmTitle: filmTitle, request: request, coordinator: self)
        navigationController?.pushViewController(trailerVC, animated: true)
    }

    func dismiss() {
        navigationController?.popViewController(animated: true)
    }
}
