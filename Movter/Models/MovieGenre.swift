//
//  MovieGenre.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import Foundation

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
    
    var sectionTitle: String {
        self == .all ? "Trending Movies" : "Trending in \(title)"
    }

    var query: DiscoverQuery {
        switch self {
        case .all:         return .trendingToday
        case .action:      return .genre(id: 28)
        case .comedy:      return .genre(id: 35)
        case .sciFi:       return .genre(id: 878)
        case .thriller:    return .genre(id: 53)
        case .horror:      return .genre(id: 27)
        case .drama:       return .genre(id: 18)
        case .anime:       return .anime
        case .documentary: return .genre(id: 99)
        }
    }
}
