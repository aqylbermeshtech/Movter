//
//  MovieFeatureExtractor.swift
//  Movter
//
//  Created by Nurtore on 11.11.2026.
//

import Foundation

enum MovieFeatureExtractor {
    static let itemFeatureDimension = 32

    /// Canonical list of standard TMDB movie genre IDs (19 genres).
    static let standardGenreIDs: [Int] = [
        28,    // Action
        12,    // Adventure
        16,    // Animation
        35,    // Comedy
        80,    // Crime
        99,    // Documentary
        18,    // Drama
        10751, // Family
        14,    // Fantasy
        36,    // History
        27,    // Horror
        10402, // Music
        9648,  // Mystery
        10749, // Romance
        878,   // Science Fiction
        10770, // TV Movie
        53,    // Thriller
        10752, // War
        37     // Western
    ]

    private static let genreIndexMap: [Int: Int] = {
        var map = [Int: Int]()
        for (index, id) in standardGenreIDs.enumerated() {
            map[id] = index
        }
        return map
    }()

    /// Extracts a fixed-size 32-dimensional item feature vector from TMDB Media metadata
    /// combined with shared global backbone latent representations.
    static func extractItemVector(
        from media: Media,
        latentVector: [Float]? = nil
    ) -> [Float] {
        var vector = [Float](repeating: 0.0, count: itemFeatureDimension)

        // 1. Multi-hot genre encoding (Indices 0..<19)
        if let genres = media.genreIds {
            for gid in genres {
                if let idx = genreIndexMap[gid] {
                    vector[idx] = 1.0
                }
            }
        }

        // 2. Release Era Bucket (Indices 19..<25)
        // [<1980, 1980-89, 1990-99, 2000-09, 2010-19, >=2020]
        let year = media.year.flatMap { Int($0) } ?? 2024
        if year < 1980 {
            vector[19] = 1.0
        } else if year < 1990 {
            vector[20] = 1.0
        } else if year < 2000 {
            vector[21] = 1.0
        } else if year < 2010 {
            vector[22] = 1.0
        } else if year < 2020 {
            vector[23] = 1.0
        } else {
            vector[24] = 1.0
        }

        // 3. Vote Average Normalization (Index 25): [0.0, 10.0] -> [0.0, 1.0]
        let voteAvg = Float(media.voteAverage)
        vector[25] = min(max(voteAvg / 10.0, 0.0), 1.0)

        // 4. Popularity / Vote Count Normalization (Index 26): Log scale
        let voteCount = Float(media.voteCount ?? 0)
        let logMaxVotes = logf(50001.0)
        let scaledVoteCount = logf(1.0 + max(voteCount, 0.0)) / logMaxVotes
        vector[26] = min(max(scaledVoteCount, 0.0), 1.0)

        // 5. Global Backbone Latent Vector (Indices 27..<32, 5 dims)
        if let latents = latentVector, latents.count == 5 {
            for i in 0..<5 {
                vector[27 + i] = latents[i]
            }
        } else {
            // Default baseline projection based on rating & genre density
            let activeGenreCount = Float(media.genreIds?.count ?? 1)
            vector[27] = min(activeGenreCount / 4.0, 1.0)
            vector[28] = vector[25] * 0.8
            vector[29] = vector[26] * 0.5
            vector[30] = (vector[25] + vector[26]) * 0.5
            vector[31] = 0.1
        }

        return vector
    }
}
