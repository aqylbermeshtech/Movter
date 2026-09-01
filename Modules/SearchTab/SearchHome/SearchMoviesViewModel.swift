//
//  SearchMoviesViewModel.swift
//  Movter
//
//  Created by Nurtore on 02.05.2026.
//

import Foundation
import UIKit

final class SearchMoviesViewModel {

    /// What a section of the browse screen draws. The two are shaped differently — a
    /// list of rows that push a category, and a single cell holding a wrapping grid of
    /// chips — so the table asks the section rather than assuming every row is a title
    /// with a chevron.
    enum Section {
        case browse(title: String, items: [String])
        case genres(title: String)
    }

    private let sections: [Section] = [
        .browse(
            title: "Browse by",
            items: ["Release date", "Genre, country or language", "Service", "Most popular", "Highest Rated", "Most anticipated", "Coming soon", "Featured lists", "Official lists"]
        ),
        .genres(title: "Popular Genres")
    ]

    var numberOfSections: Int {
        sections.count
    }

    func section(at index: Int) -> Section? {
        sections[safe: index]
    }

    func numberOfRows(in section: Int) -> Int {
        switch sections[safe: section] {
        case let .browse(_, items): return items.count
        // The grid is one cell however many chips wrap onto however many lines.
        case .genres:               return 1
        case nil:                   return 0
        }
    }

    func titleForHeader(in section: Int) -> String? {
        switch sections[safe: section] {
        case let .browse(title, _): return title
        case let .genres(title):    return title
        case nil:                   return nil
        }
    }

    func item(at indexPath: IndexPath) -> String? {
        guard case let .browse(_, items) = sections[safe: indexPath.section] else { return nil }
        return items[safe: indexPath.row]
    }

    /// The values behind a browse row, for the list it pushes. Nil for a row with
    /// nothing under it, so the screen stays put rather than pushing an empty list.
    func subcategory(at indexPath: IndexPath) -> (title: String, items: [String])? {
        guard let selectedItem = item(at: indexPath) else { return nil }
        switch selectedItem {
        case "Release date":
            return (selectedItem, ["2026", "2025", "2024", "2023", "2022", "2020s", "2010s", "2000s"])
        case "Genre, country or language":
            return (selectedItem, ["Action", "Comedy", "Drama", "Sci-Fi", "Thriller", "Horror", "Animation"])
        case "Service":
            return (selectedItem, ["Netflix", "HBO Max", "Apple TV+", "Disney+", "Amazon Prime"])
        case "Most popular":
            return (selectedItem, ["Popular Today", "Popular This Week", "All Time Popular"])
        case "Highest Rated":
            return (selectedItem, ["Top 250 Movies", "Top IMDb", "Critically Acclaimed"])
        case "Most anticipated":
            return (selectedItem, ["Coming This Month", "Most Hyped 2026", "Trending Preorders"])
        case "Coming soon":
            return (selectedItem, ["Theaters This Friday", "Streaming Next Week", "Announced Projects"])
        case "Featured lists":
            return (selectedItem, ["Oscar Winners", "Cannes Festival", "Best of Marvel", "Christopher Nolan Collection"])
        case "Official lists":
            return (selectedItem, ["TMDB Top Rated", "Letterboxd Top 250", "App Users Choice"])
        default:
            return nil
        }
    }
}
