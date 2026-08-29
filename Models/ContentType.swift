//
//  ContentType.swift
//  Movter
//
//  Created by Nurtore on 29.08.2026.
//

import Foundation

/// The three feeds the Movies tab switches between.
///
/// No `Int` raw values: the segmented control is built from `allCases`, so the running
/// order lives here and nowhere else. It used to be split — the enum's raw values had
/// to agree with a separately hard-coded array of titles in `TopSegmentedControlView`,
/// and nothing enforced that they did, so reordering the control would silently have
/// changed which feed each segment fetched.
enum ContentType: CaseIterable {
    case movies
    case tvSeries
    case articles

    /// The label on the segmented control.
    var segmentTitle: String {
        switch self {
        case .movies:   return "Movies"
        case .tvSeries: return "TV Series"
        case .articles: return "Articles"
        }
    }

    /// The heading above the list this feed fills.
    var sectionTitle: String {
        switch self {
        case .movies:   return "Trending Movies"
        case .tvSeries: return "Trending TV Shows"
        case .articles: return "Latest Film News"
        }
    }
}
