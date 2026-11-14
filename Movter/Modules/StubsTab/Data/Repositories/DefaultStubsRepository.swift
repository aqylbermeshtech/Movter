//
//  DefaultStubsRepository.swift
//  Movter
//

import Foundation

final class DefaultStubsRepository: StubsRepository {
    private let reviewsRepository: ReviewsRepository
    private let artworkDataSource: StubArtworkRemoteDataSource

    init(
        reviewsRepository: ReviewsRepository = DefaultReviewsRepository(),
        artworkDataSource: StubArtworkRemoteDataSource = TMDBStubArtworkRemoteDataSource()
    ) {
        self.reviewsRepository = reviewsRepository
        self.artworkDataSource = artworkDataSource
    }

    func fetchStubs() async throws -> [Review] {
        try await reviewsRepository.fetchAll()
    }

    func fetchStubArtwork(for review: Review) async -> StubArtwork {
        let logoURL: URL?
        if let tmdbID = review.tmdbID {
            logoURL = await artworkDataSource.fetchLogoURL(for: tmdbID)
        } else {
            logoURL = nil
        }
        return StubArtwork(posterURL: review.posterURL, logoURL: logoURL)
    }
}
