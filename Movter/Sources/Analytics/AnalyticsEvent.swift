//
//  AnalyticsEvent.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation

enum AnalyticsEvent {
    case appOpen
    case homeViewed
    case searchPerformed
    case movieDetailsViewed(movieId: String)
    case watchlistAdded(movieId: String)
    case watchlistRemoved(movieId: String)
    case reviewCreated(movieId: String)

    var name: String {
        switch self {
        case .appOpen:                          return "app_open"
        case .homeViewed:                       return "home_viewed"
        case .searchPerformed:                  return "search_performed"
        case .movieDetailsViewed:               return "movie_details_viewed"
        case .watchlistAdded:                   return "watchlist_added"
        case .watchlistRemoved:                 return "watchlist_removed"
        case .reviewCreated:                    return "review_created"
        }
    }

    var payload: [String: String] {
        switch self {
        case .appOpen, .homeViewed, .searchPerformed:
            return [:]
        case .movieDetailsViewed(let movieId):
            return ["movie_id": movieId]
        case .watchlistAdded(let movieId):
            return ["movie_id": movieId]
        case .watchlistRemoved(let movieId):
            return ["movie_id": movieId]
        case .reviewCreated(let movieId):
            return ["movie_id": movieId]
        }
    }
}
