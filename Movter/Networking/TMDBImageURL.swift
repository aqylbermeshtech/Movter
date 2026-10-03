//
//  TMDBImageURL.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// Builds TMDB image URLs from the paths the API returns.
///
/// One place for the base URL and the width vocabulary. The image cache is keyed on the
/// full URL string, so two screens showing the same artwork have to agree on the width
/// or each fetches and stores its own copy — a named case is harder to get wrong than a
/// `w500` repeated across seven files.
enum TMDBImageURL {

    /// The widths in use, named for the job rather than the pixel count.
    enum Width: String {
        /// Cast and credit thumbnails.
        case thumbnail = "w185"
        /// Actor headshots on the person screen.
        case headshot = "w342"
        /// Posters in grids, lists, and diary entries.
        case poster = "w500"
        /// Full-bleed artwork: detail headers, and the carousel's landscape backdrops.
        case wide = "w780"
    }

    private static let base = "https://image.tmdb.org/t/p/"

    /// Nil when TMDB omitted the path, which it does for titles with no artwork.
    static func url(path: String?, width: Width) -> URL? {
        guard let path = path else { return nil }
        return URL(string: base + width.rawValue + path)
    }
}
