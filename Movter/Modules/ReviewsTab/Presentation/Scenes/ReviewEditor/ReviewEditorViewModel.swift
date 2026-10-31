//
//  ReviewEditorViewModel.swift
//  Movter
//
//  Created by Nurtore on 21.08.2026.
//

import Foundation

final class ReviewEditorViewModel {

    enum Mode {
        case create
        case edit(Review)
    }

    static let maxReviewLength = 2000

    private let saveReviewUseCase: SaveReviewUseCase
    private let mode: Mode

    // MARK: - Draft

    private(set) var filmTitle: String = ""
    private(set) var filmYear: String?
    private(set) var tmdbID: Int?
    private(set) var posterPath: String?
    private(set) var backdropPath: String?

    var score: Int = 0
    var reviewText: String = ""

    init(
        saveReviewUseCase: SaveReviewUseCase = DefaultSaveReviewUseCase(repository: DefaultReviewsRepository()),
        mode: Mode
    ) {
        self.saveReviewUseCase = saveReviewUseCase
        self.mode = mode

        if case let .edit(review) = mode {
            filmTitle = review.filmTitle
            filmYear = review.filmYear
            tmdbID = review.tmdbID
            posterPath = review.posterPath
            backdropPath = review.backdropPath
            score = review.score
            reviewText = review.reviewText
        }
    }

    convenience init(store: ReviewStoring, mode: Mode) {
        self.init(
            saveReviewUseCase: DefaultSaveReviewUseCase(repository: DefaultReviewsRepository()),
            mode: mode
        )
    }

    // MARK: - Presentation

    var screenTitle: String {
        if case .edit = mode { return "Edit Review" }
        return "New Review"
    }

    var saveButtonTitle: String {
        if case .edit = mode { return "Save Changes" }
        return "Save Review"
    }

    var hasFilm: Bool { !filmTitle.isEmpty }

    var posterURL: URL? { TMDBImageURL.url(path: posterPath, width: .poster) }

    var filmSubtitle: String {
        guard hasFilm else { return "Search the catalogue, or add one by hand" }
        var parts: [String] = []
        if let filmYear = filmYear, !filmYear.isEmpty { parts.append(filmYear) }
        parts.append(tmdbID == nil ? "Added manually" : "From catalogue")
        return parts.joined(separator: "  ·  ")
    }

    var scoreText: String {
        score == 0 ? "Tap to score" : "\(score)/10"
    }

    var remainingCharactersText: String? {
        let remaining = Self.maxReviewLength - reviewText.count
        guard remaining <= 200 else { return nil }
        return "\(remaining) characters left"
    }

    var canSave: Bool {
        hasFilm && Review.scoreRange.contains(score)
    }

    // MARK: - Editing

    func apply(_ selection: FilmSelection) {
        switch selection {
        case let .catalogue(media):
            filmTitle = media.displayName
            filmYear = media.year
            tmdbID = media.id
            posterPath = media.posterPath
            backdropPath = media.backdropPath
        case let .manual(title):
            filmTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            filmYear = nil
            tmdbID = nil
            posterPath = nil
            backdropPath = nil
        }
    }

    func save() async throws {
        guard canSave else { throw ReviewError.emptyFilmTitle }

        let review: Review
        switch mode {
        case .create:
            review = Review(
                filmTitle: filmTitle,
                filmYear: filmYear,
                tmdbID: tmdbID,
                posterPath: posterPath,
                backdropPath: backdropPath,
                score: score,
                reviewText: reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        case let .edit(existing):
            review = Review(
                id: existing.id,
                filmTitle: filmTitle,
                filmYear: filmYear,
                tmdbID: tmdbID,
                posterPath: posterPath,
                backdropPath: backdropPath,
                score: score,
                reviewText: reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: existing.createdAt
            )
        }

        try await saveReviewUseCase.execute(review)
    }

    func save(completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await save()
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
