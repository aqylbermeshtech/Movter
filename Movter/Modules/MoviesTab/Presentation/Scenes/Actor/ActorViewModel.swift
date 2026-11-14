//
//  ActorViewModel.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import UIKit

@MainActor
final class ActorViewModel {

    private let actorId: Int
    private let fallbackName: String
    private let detailsUseCase: GetPersonDetailsUseCase
    private let creditsUseCase: GetPersonCreditsUseCase
    private weak var coordinator: MoviesCoordinator?
    private let monitor: NetworkMonitoring

    private(set) var details: PersonDetails?
    private(set) var credits: [PersonCredit] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var didFailToLoadDetails = false

    var onUpdate: (() -> Void)?

    init(
        actorId: Int,
        name: String,
        detailsUseCase: GetPersonDetailsUseCase = DefaultGetPersonDetailsUseCase(),
        creditsUseCase: GetPersonCreditsUseCase = DefaultGetPersonCreditsUseCase(),
        coordinator: MoviesCoordinator? = nil,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.actorId = actorId
        self.fallbackName = name
        self.detailsUseCase = detailsUseCase
        self.creditsUseCase = creditsUseCase
        self.coordinator = coordinator
        self.monitor = monitor
    }

    convenience init(
        actorId: Int,
        name: String,
        service: MediaFetching = TMDBService.shared,
        monitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        let repo = DefaultPersonRepository(remoteDataSource: TMDBMoviesRemoteDataSource(service: service))
        self.init(
            actorId: actorId,
            name: name,
            detailsUseCase: DefaultGetPersonDetailsUseCase(repository: repo),
            creditsUseCase: DefaultGetPersonCreditsUseCase(repository: repo),
            coordinator: nil,
            monitor: monitor
        )
    }

    func connectivityDidChange() {
        guard monitor.isOnline, credits.isEmpty else { return }
        hasLoaded = false
        load()
    }

    // MARK: - Display text

    var name: String { details?.name ?? fallbackName }

    var profileURL: URL? { details?.profileURL }

    var subtitleText: String? {
        var parts: [String] = []
        if let department = details?.knownForDepartment, !department.isEmpty {
            parts.append(department)
        }
        if let lifespan = lifespanText {
            parts.append(lifespan)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var birthplaceText: String? {
        guard let place = details?.placeOfBirth, !place.isEmpty else { return nil }
        return place
    }

    var biographyText: String {
        guard let biography = details?.biography?.trimmingCharacters(in: .whitespacesAndNewlines),
              !biography.isEmpty else {
            return "No biography available for \(name) yet."
        }
        return biography
    }

    var hasBiography: Bool {
        guard let biography = details?.biography?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return !biography.isEmpty
    }

    var filmographyCountText: String {
        credits.isEmpty ? "Filmography" : "Filmography (\(credits.count))"
    }

    var emptyFilmographyText: String {
        if !monitor.isOnline { return "You're offline. Filmography loads when you reconnect." }
        return didFailToLoadDetails ? "Couldn’t load filmography." : "No credits listed for \(name) yet."
    }

    private var lifespanText: String? {
        guard let birthday = details?.birthday, let born = Self.isoFormatter.date(from: birthday) else { return nil }
        let bornText = Self.displayFormatter.string(from: born)

        if let deathday = details?.deathday, let died = Self.isoFormatter.date(from: deathday) {
            let age = Calendar.current.dateComponents([.year], from: born, to: died).year
            let diedText = Self.displayFormatter.string(from: died)
            return age.map { "\(bornText) – \(diedText) (aged \($0))" } ?? "\(bornText) – \(diedText)"
        }

        guard let age = Calendar.current.dateComponents([.year], from: born, to: Date()).year else {
            return "Born \(bornText)"
        }
        return "Born \(bornText) (age \(age))"
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Loading

    func load() {
        guard !isLoading else { return }
        isLoading = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                async let details = self.detailsUseCase.execute(for: self.actorId)
                async let credits = self.creditsUseCase.execute(for: self.actorId)
                let (fetchedDetails, fetchedCredits) = try await (details, credits)
                self.details = fetchedDetails
                self.credits = fetchedCredits
                self.didFailToLoadDetails = false
            } catch {
                self.didFailToLoadDetails = true
            }
            self.isLoading = false
            self.hasLoaded = true
            self.onUpdate?()
        }
    }

    func credit(at index: Int) -> PersonCredit? {
        credits.indices.contains(index) ? credits[index] : nil
    }

    func showMovieDetails(media: Media, from source: UIViewController & PosterTransitionSource) {
        coordinator?.showMovieDetails(media: media, from: source)
    }
}

