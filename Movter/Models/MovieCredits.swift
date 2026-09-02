//
//  MovieCredits.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import Foundation

nonisolated struct MovieCredits: Codable {
    let cast: [Actor]
}

nonisolated struct Actor: Codable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?

    var profileURL: URL? { TMDBImageURL.url(path: profilePath, width: .thumbnail) }
}
