//
//  MediaType.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// Which half of TMDB's catalogue a title belongs to.
///
/// Replaces the `isTV: Bool` that used to thread through the networking API. A call
/// site reading `fetchActors(for: id, type: .tv)` says what `isTV: true` did not, and
/// the raw value doubles as the path segment TMDB expects.
enum MediaType: String, Hashable, CaseIterable {
    case movie
    case tv

    /// TMDB's URL path segment: `/movie/…` or `/tv/…`.
    var path: String { rawValue }
}
