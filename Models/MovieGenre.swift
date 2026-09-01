//
//  MovieGenre.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import Foundation

/// The genre filters offered on the home screen, carrying TMDB's own genre ids.
///
/// A short fixed list rather than TMDB's full genre table: the chip row is a shortcut
/// into the catalogue, not a complete taxonomy — Search already browses the long tail,
/// and a row of eighteen chips nobody scrolls to the end of is worse than seven.
enum MovieGenre: CaseIterable {
    case all
    case action
    case comedy
    case sciFi
    case thriller
    case horror
    case animation
    case drama

    var title: String {
        switch self {
        case .all:       return "All"
        case .action:    return "Action"
        case .comedy:    return "Comedy"
        case .sciFi:     return "Sci-Fi"
        case .thriller:  return "Thriller"
        case .horror:    return "Horror"
        case .animation: return "Animation"
        case .drama:     return "Drama"
        }
    }

    /// Nil for `.all`, which is the trending feed rather than a filter over it.
    private var tmdbID: Int? {
        switch self {
        case .all:       return nil
        case .action:    return 28
        case .comedy:    return 35
        case .sciFi:     return 878
        case .thriller:  return 53
        case .horror:    return 27
        case .animation: return 16
        case .drama:     return 18
        }
    }

    /// What the poster row under the hero is called once this chip is picked.
    var sectionTitle: String {
        self == .all ? "Trending Movies" : "Trending in \(title)"
    }

    /// The request behind the chip — the same query the row's "See all" opens, so the
    /// grid can't disagree with the row that led to it.
    var query: DiscoverQuery {
        guard let tmdbID = tmdbID else { return .trendingToday }
        return .genre(id: tmdbID)
    }
}
