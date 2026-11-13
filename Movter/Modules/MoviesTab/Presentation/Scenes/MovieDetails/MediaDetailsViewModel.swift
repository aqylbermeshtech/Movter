//
//  MediaDetailsViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

@MainActor
final class MediaDetailsViewModel {
    private let media: Media
    private let creditsUseCase: GetMovieCreditsUseCase
    private let similarUseCase: GetSimilarMoviesUseCase
    private let trailerUseCase: GetTrailerUseCase
    private let detailsRepository: MovieDetailsRepository
    private let watchStatusUseCase: GetMediaWatchStatusUseCase
    private let toggleWatchlistUseCase: ToggleWatchlistUseCase
    private let toggleWatchedUseCase: ToggleWatchedUseCase
    private let getReviewUseCase: GetUserReviewForMovieUseCase
    private let saveReviewUseCase: SaveUserReviewUseCase
    private weak var coordinator: MoviesCoordinator?
    private let monitor: NetworkMonitoring

    var onVideoUpdate: ((String?) -> Void)?
    private(set) var videoKey: String?

    var onCreditsUpdate: (() -> Void)?
    var actors: [Actor] = []
    private(set) var crew: [CrewMember] = []
    private(set) var hasLoadedActors = false
    private(set) var didFailToLoadActors = false
    var hasCredits: Bool { !actors.isEmpty || !crew.isEmpty }

    // MARK: - More like this
    static let similarLimit = 8
    private(set) var similar: [Media] = []
    var onSimilarUpdate: (() -> Void)?
    var hasSimilar: Bool { !similar.isEmpty }

    var title: String { media.displayName }
    var overview: String { media.overview }
    var posterPath: String { media.posterPath ?? "" }
    var releaseDate: String { media.releaseDate ?? media.firstAirDate ?? "N/A" }
    var voteAverage: Double { media.voteAverage }
    var ratingState: RatingState { media.ratingState }
    var year: String? { media.year }
    var largeImageURL: URL? { media.largePosterURL ?? media.fullPosterURL }
    private var mediaType: MediaType { media.mediaType }

    private(set) var genreName: String?
    var onGenreUpdate: (() -> Void)?

    // MARK: - Watchlist
    private(set) var isInWatchlist = false
    var onWatchlistChange: (() -> Void)?
    var watchlistButtonTitle: String { isInWatchlist ? "In watchlist" : "Add to watchlist" }
    var watchlistButtonSymbol: String { isInWatchlist ? "bookmark.fill" : "bookmark" }

    // MARK: - Watched
    private(set) var isWatched = false
    var onWatchedChange: (() -> Void)?
    var watchedButtonTitle: String { isWatched ? "Watched" : "Mark as watched" }
    var watchedButtonSymbol: String { isWatched ? "checkmark.circle.fill" : "checkmark.circle" }

    // MARK: - Review
    private(set) var existingReview: Review?
    var onReviewUpdate: (() -> Void)?

    init(
        media: Media,
        creditsUseCase: GetMovieCreditsUseCase = DefaultGetMovieCreditsUseCase(),
        similarUseCase: GetSimilarMoviesUseCase = DefaultGetSimilarMoviesUseCase(),
        trailerUseCase: GetTrailerUseCase = DefaultGetTrailerUseCase(),
        detailsRepository: MovieDetailsRepository = DefaultMovieDetailsRepository(),
        watchStatusUseCase: GetMediaWatchStatusUseCase = DefaultGetMediaWatchStatusUseCase(),
        toggleWatchlistUseCase: ToggleWatchlistUseCase = DefaultToggleWatchlistUseCase(),
        toggleWatchedUseCase: ToggleWatchedUseCase = DefaultToggleWatchedUseCase(),
        getReviewUseCase: GetUserReviewForMovieUseCase = DefaultGetUserReviewForMovieUseCase(),
        saveReviewUseCase: SaveUserReviewUseCase = DefaultSaveUserReviewUseCase(),
        coordinator: MoviesCoordinator? = nil,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.media = media
        self.creditsUseCase = creditsUseCase
        self.similarUseCase = similarUseCase
        self.trailerUseCase = trailerUseCase
        self.detailsRepository = detailsRepository
        self.watchStatusUseCase = watchStatusUseCase
        self.toggleWatchlistUseCase = toggleWatchlistUseCase
        self.toggleWatchedUseCase = toggleWatchedUseCase
        self.getReviewUseCase = getReviewUseCase
        self.saveReviewUseCase = saveReviewUseCase
        self.coordinator = coordinator
        self.monitor = monitor
    }

    convenience init(
        media: Media,
        reviewStore: ReviewStoring = ReviewStoreFactory.makeStore(),
        watchedStore: WatchlistStoring = WatchedFilmsStoreFactory.makeStore(),
        watchlistStore: WatchlistStoring = WatchlistStoreFactory.makeStore(),
        service: MediaFetching = TMDBService.shared,
        genreProvider: GenreProviding = GenreProvider.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        let detailsRepo = DefaultMovieDetailsRepository(remoteDataSource: TMDBMoviesRemoteDataSource(service: service))
        self.init(
            media: media,
            creditsUseCase: DefaultGetMovieCreditsUseCase(repository: detailsRepo),
            similarUseCase: DefaultGetSimilarMoviesUseCase(repository: detailsRepo),
            trailerUseCase: DefaultGetTrailerUseCase(repository: detailsRepo),
            detailsRepository: detailsRepo,
            watchStatusUseCase: DefaultGetMediaWatchStatusUseCase(),
            toggleWatchlistUseCase: DefaultToggleWatchlistUseCase(),
            toggleWatchedUseCase: DefaultToggleWatchedUseCase(),
            getReviewUseCase: DefaultGetUserReviewForMovieUseCase(),
            saveReviewUseCase: DefaultSaveUserReviewUseCase(),
            coordinator: nil,
            monitor: monitor
        )
    }

    func loadWatchlistState() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let status = try await self.watchStatusUseCase.execute(mediaId: self.media.id)
                self.isInWatchlist = status.isWatchlisted
                self.isWatched = status.isWatched
                self.onWatchlistChange?()
                self.onWatchedChange?()
            } catch {}
        }
    }

    func toggleWatchlist() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let inWatchlist = try await self.toggleWatchlistUseCase.execute(for: self.media)
                self.isInWatchlist = inWatchlist
                self.onWatchlistChange?()
            } catch {}
        }
    }

    func loadWatchedState() {
        loadWatchlistState()
    }

    func toggleWatched() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let status = try await self.toggleWatchedUseCase.execute(for: self.media)
                self.isInWatchlist = status.isWatchlisted
                self.isWatched = status.isWatched
                self.onWatchlistChange?()
                self.onWatchedChange?()
            } catch {}
        }
    }

    func markWatchedIfNeeded() {
        guard !isWatched else { return }
        toggleWatched()
    }

    func loadReview() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                self.existingReview = try await self.getReviewUseCase.execute(for: self.media.id)
                self.onReviewUpdate?()
            } catch {}
        }
    }

    func saveReview(score: Int, text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let review: Review
        if let existing = existingReview {
            review = Review(
                id: existing.id,
                filmTitle: existing.filmTitle,
                filmYear: existing.filmYear,
                tmdbID: existing.tmdbID,
                posterPath: existing.posterPath,
                backdropPath: existing.backdropPath ?? media.backdropPath,
                score: score,
                reviewText: trimmed,
                createdAt: existing.createdAt
            )
        } else {
            review = Review(from: media, score: score, reviewText: trimmed)
        }

        Task { [weak self] in
            do {
                try await self?.saveReviewUseCase.execute(review)
                self?.existingReview = review
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    var castPlaceholderTitle: String {
        if !monitor.isOnline { return "You're offline" }
        return didFailToLoadActors ? "Couldn't load the cast" : "No cast information"
    }

    var castPlaceholderSubtitle: String {
        if !monitor.isOnline { return "The cast will load when you reconnect" }
        return didFailToLoadActors
            ? "Please try again"
            : "TMDB doesn't list a cast for this title yet"
    }

    func connectivityDidChange() {
        guard monitor.isOnline else { return }
        if actors.isEmpty { fetchCredits() }
        if similar.isEmpty { fetchSimilar() }
        fetchTrailer()
    }

    func fetchGenre() {
        Task { [weak self] in
            guard let self = self else { return }
            let name = await self.detailsRepository.fetchPrimaryGenreName(genreIds: self.media.genreIds, type: self.mediaType)
            if let name = name {
                self.genreName = name
                self.onGenreUpdate?()
            }
        }
    }

    func fetchTrailer() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let key = try await self.trailerUseCase.execute(for: self.media.id, type: self.mediaType)
                self.videoKey = key
                self.onVideoUpdate?(key)
            } catch {
                self.videoKey = nil
                self.onVideoUpdate?(nil)
            }
        }
    }

    func youtubeRequest(for key: String) -> URLRequest? {
        let urlString = "https://www.youtube.com/embed/\(key)?enablejsapi=1&origin=https://www.themoviedb.org"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("https://www.themoviedb.org", forHTTPHeaderField: "Referer")
        return request
    }

    var trailerRequest: URLRequest? {
        guard let key = videoKey else { return nil }
        return youtubeRequest(for: key)
    }

    func fetchCredits() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let credits = try await self.creditsUseCase.execute(for: self.media.id, type: self.mediaType)
                self.didFailToLoadActors = false
                self.actors = credits.cast
                self.crew = credits.crew ?? []
                self.hasLoadedActors = true
                self.onCreditsUpdate?()
            } catch {
                self.didFailToLoadActors = true
                self.actors = []
                self.crew = []
                self.hasLoadedActors = true
                self.onCreditsUpdate?()
            }
        }
    }

    func fetchSimilar() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let similarItems = try await self.similarUseCase.execute(
                    for: self.media.id,
                    type: self.mediaType,
                    limit: Self.similarLimit
                )
                self.similar = similarItems
                self.onSimilarUpdate?()
            } catch {
                self.similar = []
                self.onSimilarUpdate?()
            }
        }
    }

    // MARK: - Navigation
    func showCastCrew() {
        coordinator?.showCastCrew(mediaTitle: title, cast: actors, crew: crew)
    }

    func showTrailer() {
        guard let request = trailerRequest else { return }
        coordinator?.showTrailer(filmTitle: title, request: request)
    }

    func showActorDetails(actorId: Int, name: String) {
        coordinator?.showActorDetails(actorId: actorId, name: name)
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        coordinator?.showMovieDetails(media: media, from: source)
    }

    func makeCastCrewViewModel() -> CastCrewViewModel {
        CastCrewViewModel(mediaTitle: title, cast: actors, crew: crew, coordinator: coordinator)
    }
}

