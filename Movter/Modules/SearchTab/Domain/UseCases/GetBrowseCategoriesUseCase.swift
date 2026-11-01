//
//  GetBrowseCategoriesUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol GetBrowseCategoriesUseCase {
    func execute() -> [SearchBrowserCategory]
    func subcategory(for categoryTitle: String) -> [String]?
}

final class DefaultGetBrowseCategoriesUseCase: GetBrowseCategoriesUseCase {

    private let categories: [SearchBrowserCategory] = [
        SearchBrowserCategory(
            title: "Release date",
            items: ["2026", "2025", "2024", "2023", "2022", "2020s", "2010s", "2000s"]
        ),
        SearchBrowserCategory(
            title: "Service",
            items: ["Netflix", "HBO Max", "Apple TV+", "Disney+", "Amazon Prime"]
        ),
        SearchBrowserCategory(
            title: "Most popular",
            items: ["Popular Today", "Popular This Week", "All Time Popular"]
        ),
        SearchBrowserCategory(
            title: "Highest Rated",
            items: ["Top 250 Movies", "Top IMDb", "Critically Acclaimed"]
        ),
        SearchBrowserCategory(
            title: "Most anticipated",
            items: ["Coming This Month", "Most Hyped 2026", "Trending Preorders"]
        ),
        SearchBrowserCategory(
            title: "Coming soon",
            items: ["Theaters This Friday", "Streaming Next Week", "Announced Projects"]
        ),
        SearchBrowserCategory(
            title: "Featured lists",
            items: ["Oscar Winners", "Cannes Festival", "Best of Marvel", "Christopher Nolan Collection"]
        ),
        SearchBrowserCategory(
            title: "Official lists",
            items: ["TMDB Top Rated", "Letterboxd Top 250", "App Users Choice"]
        )
    ]

    func execute() -> [SearchBrowserCategory] {
        categories
    }

    func subcategory(for categoryTitle: String) -> [String]? {
        categories.first { $0.title == categoryTitle }?.items
    }
}

