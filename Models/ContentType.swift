//
//  ContentType.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

enum ContentType: CaseIterable {
    case movies
    case tvSeries
    case articles

    var segmentTitle: String {
        switch self {
        case .movies:   return "Movies"
        case .tvSeries: return "TV Series"
        case .articles: return "Articles"
        }
    }

    var sectionTitle: String {
        switch self {
        case .movies:   return "Trending Movies"
        case .tvSeries: return "Trending TV Shows"
        case .articles: return "Latest Film News"
        }
    }
}
