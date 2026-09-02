//
//  MovieGenre.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import Foundation

/// The genres the app offers as a shortcut into the catalogue — the home screen's
/// filter row and the browse screen's chip grid draw from this same list.
///
/// A short fixed set rather than TMDB's full genre table: these are a way in, not a
/// complete taxonomy — Search already browses the long tail, and a row of eighteen
/// chips nobody scrolls to the end of is worse than nine.
enum MovieGenre: CaseIterable {
    case all
    case action
    case comedy
    case sciFi
    case thriller
    case horror
    case drama
    case anime
    case documentary

    var title: String {
        switch self {
        case .all:         return "All"
        case .action:      return "Action"
        case .comedy:      return "Comedy"
        case .sciFi:       return "Sci-Fi"
        case .thriller:    return "Thriller"
        case .horror:      return "Horror"
        case .drama:       return "Drama"
        case .anime:       return "Anime"
        case .documentary: return "Documentary"
        }
    }

    /// What the feed under this genre is called, wherever it's opened from — the poster
    /// row on home, and the grid its "See all" and the browse chips both push.
    var sectionTitle: String {
        self == .all ? "Trending Movies" : "Trending in \(title)"
    }

    /// The request behind the chip, so the row and the grid opened from it can't
    /// disagree about what the chip meant.
    var query: DiscoverQuery {
        switch self {
        case .all:         return .trendingToday
        case .action:      return .genre(id: 28)
        case .comedy:      return .genre(id: 35)
        case .sciFi:       return .genre(id: 878)
        case .thriller:    return .genre(id: 53)
        case .horror:      return .genre(id: 27)
        case .drama:       return .genre(id: 18)
        // TMDB has no anime genre of its own; see `DiscoverQuery.anime`.
        case .anime:       return .anime
        case .documentary: return .genre(id: 99)
        }
    }
}
