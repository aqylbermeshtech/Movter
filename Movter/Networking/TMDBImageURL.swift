//
//  TMDBImageURL.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

enum TMDBImageURL {

    enum Width: String {
        case thumbnail = "w185"
        case headshot = "w342"
        case poster = "w500"
        case wide = "w780"
    }

    private static let base = "https://image.tmdb.org/t/p/"

    static func url(path: String?, width: Width) -> URL? {
        guard let path = path else { return nil }
        return URL(string: base + width.rawValue + path)
    }
}
