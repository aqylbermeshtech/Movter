//
//  WatchlistPresentationType.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum WatchlistPresentationType: Equatable {
    case watchlist
    case watched

    var title: String {
        switch self {
        case .watchlist: return "Watchlist"
        case .watched: return "Watched"
        }
    }

    var emptyTitle: String {
        switch self {
        case .watchlist: return "Nothing here yet"
        case .watched: return "Nothing watched yet"
        }
    }

    var emptyBody: String {
        switch self {
        case .watchlist: return "Swipe right on a film in the Swipe tab and it'll show up here."
        case .watched: return "Mark a film as watched on its page and it'll show up here."
        }
    }

    var datePrefix: String {
        switch self {
        case .watchlist: return "Added"
        case .watched: return "Watched"
        }
    }

    var removeActionTitle: String {
        switch self {
        case .watchlist: return "Remove"
        case .watched: return "Unmark"
        }
    }

    var removeTitle: String {
        removeActionTitle
    }

    var storageName: String {
        switch self {
        case .watchlist: return "watchlist"
        case .watched: return "watched"
        }
    }
}
