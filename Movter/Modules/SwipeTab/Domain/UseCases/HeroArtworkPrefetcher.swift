//
//  HeroArtworkPrefetcher.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

protocol HeroArtworkPrefetching {
    func prefetchHeroArtwork(for media: Media) async
}

final class DefaultHeroArtworkPrefetcher: HeroArtworkPrefetching {
    func prefetchHeroArtwork(for media: Media) async {
        let artwork = await TMDBService.shared.fetchHeroArtwork(for: media.id, type: media.mediaType)
        if let textlessPath = artwork.textlessPosterPath,
           textlessPath != media.posterPath,
           let textlessURL = TMDBImageURL.url(path: textlessPath, width: .wide) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                ImageLoader.load(url: textlessURL) { _ in
                    continuation.resume()
                }
            }
        }
        if let logoPath = artwork.logoPath,
           let logoURL = TMDBImageURL.url(path: logoPath, width: .poster) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                ImageLoader.load(url: logoURL) { _ in
                    continuation.resume()
                }
            }
        }
    }
}
