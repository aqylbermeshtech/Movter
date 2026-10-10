//
//  DiscoverQuery.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

struct DiscoverQuery {

    let path: String
    let queryItems: [URLQueryItem]

    private init(_ path: String, _ items: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = items
    }

    private static func discover(_ items: [String: String]) -> DiscoverQuery {
        DiscoverQuery("/discover/movie", items.map { URLQueryItem(name: $0.key, value: $0.value) })
    }

    static let trendingToday = DiscoverQuery("/trending/movie/day")

    static func genre(id: Int) -> DiscoverQuery {
        discover(["with_genres": "\(id)", "sort_by": "popularity.desc"])
    }

    static let anime = discover([
        "with_genres": "16",
        "with_original_language": "ja",
        "sort_by": "popularity.desc"
    ])

    static func make(category: String, value: String) -> DiscoverQuery? {
        switch category {
        case "Release date":       return releaseDate(value)
        case "Service":            return service(value)
        case "Most popular":       return mostPopular(value)
        case "Highest Rated":      return highestRated(value)
        case "Most anticipated":   return mostAnticipated(value)
        case "Coming soon":        return comingSoon(value)
        case "Featured lists":     return featured(value)
        case "Official lists":     return official(value)
        default:                   return nil
        }
    }

    // MARK: - Categories

    private static func releaseDate(_ value: String) -> DiscoverQuery? {
        if value.hasSuffix("s"), let start = Int(value.dropLast()) {
            return discover([
                "primary_release_date.gte": "\(start)-01-01",
                "primary_release_date.lte": "\(start + 9)-12-31",
                "sort_by": "popularity.desc"
            ])
        }
        guard let year = Int(value) else { return nil }
        return discover(["primary_release_year": "\(year)", "sort_by": "popularity.desc"])
    }

    private static func service(_ value: String) -> DiscoverQuery? {
        guard let id = providerIds[value.lowercased()] else { return nil }
        return discover([
            "with_watch_providers": id,
            "watch_region": "US",
            "sort_by": "popularity.desc"
        ])
    }

    private static func mostPopular(_ value: String) -> DiscoverQuery? {
        switch value {
        case "Popular Today":     return DiscoverQuery("/movie/popular")
        case "Popular This Week": return DiscoverQuery("/trending/movie/week")
        case "All Time Popular":
            return discover(["sort_by": "vote_count.desc", "vote_count.gte": "5000"])
        default: return nil
        }
    }

    private static func highestRated(_ value: String) -> DiscoverQuery? {
        switch value {
        case "Top 250 Movies", "TMDB Top Rated":
            return DiscoverQuery("/movie/top_rated")
        case "Critically Acclaimed":
            return discover(["sort_by": "vote_average.desc", "vote_count.gte": "3000"])
        default: return nil
        }
    }

    private static func mostAnticipated(_ value: String) -> DiscoverQuery? {
        let today = isoDay(Date())
        switch value {
        case "Coming This Month":
            return discover([
                "primary_release_date.gte": today,
                "primary_release_date.lte": isoDay(Date().addingTimeInterval(30 * 86_400)),
                "sort_by": "popularity.desc"
            ])
        case "Most Hyped 2026", "Trending Preorders":
            return discover(["primary_release_date.gte": today, "sort_by": "popularity.desc"])
        default: return nil
        }
    }

    private static func comingSoon(_ value: String) -> DiscoverQuery? {
        switch value {
        case "Theaters This Friday":
            return DiscoverQuery("/movie/upcoming")
        case "Streaming Next Week":
            return discover([
                "primary_release_date.gte": isoDay(Date()),
                "primary_release_date.lte": isoDay(Date().addingTimeInterval(14 * 86_400)),
                "with_watch_monetization_types": "flatrate",
                "watch_region": "US",
                "sort_by": "popularity.desc"
            ])
        case "Announced Projects":
            return discover([
                "primary_release_date.gte": isoDay(Date().addingTimeInterval(180 * 86_400)),
                "sort_by": "popularity.desc"
            ])
        default: return nil
        }
    }

    private static func featured(_ value: String) -> DiscoverQuery? {
        switch value {
        case "Best of Marvel":
            return discover(["with_companies": "420", "sort_by": "popularity.desc"])
        case "Christopher Nolan Collection":
            return discover(["with_crew": "525", "sort_by": "primary_release_date.desc"])
        default: return nil
        }
    }

    private static func official(_ value: String) -> DiscoverQuery? {
        switch value {
        case "TMDB Top Rated": return DiscoverQuery("/movie/top_rated")
        default: return nil
        }
    }

    // MARK: - Lookups

    private static let providerIds: [String: String] = [
        "netflix": "8", "hbo max": "384", "apple tv+": "350",
        "disney+": "337", "amazon prime": "9"
    ]

    private static func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
