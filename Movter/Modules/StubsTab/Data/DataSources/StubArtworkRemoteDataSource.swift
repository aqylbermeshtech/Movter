//
//  StubArtworkRemoteDataSource.swift
//  Movter
//

import Foundation

protocol StubArtworkRemoteDataSource {
    func fetchLogoURL(for tmdbID: Int) async -> URL?
}

final class TMDBStubArtworkRemoteDataSource: StubArtworkRemoteDataSource {
    private let service: TMDBService

    init(service: TMDBService = .shared) {
        self.service = service
    }

    func fetchLogoURL(for tmdbID: Int) async -> URL? {
        let artwork = await service.fetchHeroArtwork(for: tmdbID, type: .movie)
        guard let logoPath = artwork.logoPath else { return nil }
        return TMDBImageURL.url(path: logoPath, width: .poster)
    }
}
