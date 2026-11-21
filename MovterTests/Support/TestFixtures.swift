import Foundation
@testable import Movter

enum TestFixtures {

    // MARK: - Deterministic Dates

    static func makeDate(year: Int, month: Int = 1, day: Int = 1) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    // MARK: - Media

    static func makeMedia(
        id: Int = 100,
        title: String? = "Test Film",
        name: String? = nil,
        overview: String = "Test overview",
        posterPath: String? = "/poster.jpg",
        backdropPath: String? = "/backdrop.jpg",
        releaseDate: String? = "2024-03-15",
        firstAirDate: String? = nil,
        voteAverage: Double = 7.6,
        voteCount: Int? = 500,
        genreIds: [Int]? = [28, 12]
    ) -> Media {
        Media(
            id: id,
            title: title,
            name: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            firstAirDate: firstAirDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genreIds: genreIds
        )
    }

    static func makeMediaList(count: Int, startingID: Int = 1, genreIds: [Int]? = [28]) -> [Media] {
        (0..<count).map { offset in
            let id = startingID + offset
            return makeMedia(id: id, title: "Film \(id)", genreIds: genreIds)
        }
    }

    // MARK: - Cross-Tab Models

    static func makeWatchlistItem(
        id: UUID = UUID(),
        tmdbID: Int = 100,
        title: String = "Test Watchlist Film",
        year: String? = "2024",
        releaseDate: String? = "2024-03-15",
        posterPath: String? = "/poster.jpg",
        addedAt: Date = makeDate(year: 2026, month: 6, day: 1)
    ) -> WatchlistItem {
        WatchlistItem(
            id: id,
            tmdbID: tmdbID,
            title: title,
            year: year,
            releaseDate: releaseDate,
            posterPath: posterPath,
            addedAt: addedAt
        )
    }

    static func makeReview(
        id: UUID = UUID(),
        filmTitle: String = "Reviewed Film",
        filmYear: String? = "2023",
        tmdbID: Int? = 200,
        posterPath: String? = "/poster.jpg",
        backdropPath: String? = "/backdrop.jpg",
        score: Int = 8,
        reviewText: String = "Great pacing.",
        createdAt: Date = makeDate(year: 2026, month: 5, day: 1),
        updatedAt: Date = makeDate(year: 2026, month: 5, day: 2)
    ) -> Review {
        Review(
            id: id,
            filmTitle: filmTitle,
            filmYear: filmYear,
            tmdbID: tmdbID,
            posterPath: posterPath,
            backdropPath: backdropPath,
            score: score,
            reviewText: reviewText,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeFavoriteFilm(
        id: Int = 300,
        title: String = "Favorite Film",
        posterPath: String? = "/poster.jpg",
        year: String? = "2022"
    ) -> FavoriteFilm {
        FavoriteFilm(id: id, title: title, posterPath: posterPath, year: year)
    }

    // MARK: - Networking / Queries

    static func makeDiscoverQuery(genreID: Int = 878) -> DiscoverQuery {
        DiscoverQuery.genre(id: genreID)
    }

    static func makeMediaPage(items: [Media], isLastPage: Bool = true) -> MediaPage {
        MediaPage(items: items, isLastPage: isLastPage)
    }
}
