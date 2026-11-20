//
//  LibraryViewModel.swift
//  Movter
//

import Combine
import Foundation
import SwiftUI

enum LibraryFolder: String, CaseIterable, Identifiable {
    case watchlist
    case comingSoon
    case favorites
    case seen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watchlist: return "Watchlist"
        case .comingSoon: return "Coming Soon"
        case .favorites: return "Favorites"
        case .seen: return "Seen"
        }
    }

    var symbol: String {
        switch self {
        case .watchlist: return "bookmark.fill"
        case .comingSoon: return "clock.fill"
        case .favorites: return "heart.fill"
        case .seen: return "eye.fill"
        }
    }

    var activeColor: Color {
        switch self {
        case .watchlist:
            return Color(red: 0.62, green: 0.31, blue: 0.96)
        case .comingSoon:
            return Color(red: 0.18, green: 0.78, blue: 0.38)
        case .favorites:
            return Color(red: 0.92, green: 0.24, blue: 0.28)
        case .seen:
            return Color(red: 0.45, green: 0.45, blue: 0.49)
        }
    }
}

struct LibraryMediaItem: Identifiable, Equatable {
    let id: String
    let tmdbID: Int
    let title: String
    let year: String?
    let releaseDate: String?
    let posterPath: String?
    let subtitle: String?

    init(
        id: String,
        tmdbID: Int,
        title: String,
        year: String?,
        releaseDate: String? = nil,
        posterPath: String?,
        subtitle: String?
    ) {
        self.id = id
        self.tmdbID = tmdbID
        self.title = title
        self.year = year
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.subtitle = subtitle
    }

    var posterURL: URL? {
        TMDBImageURL.url(path: posterPath, width: .poster)
    }

    var asMedia: Media {
        Media(
            id: tmdbID,
            title: title,
            name: nil,
            overview: "",
            posterPath: posterPath,
            backdropPath: nil,
            releaseDate: releaseDate ?? year,
            firstAirDate: nil,
            voteAverage: 0,
            voteCount: nil,
            genreIds: nil
        )
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedFolder: LibraryFolder = .watchlist
    @Published private(set) var itemsByFolder: [LibraryFolder: [LibraryMediaItem]] = [:]

    private let watchlistRepository: WatchlistRepository
    private let favoritesRepository: TopFavoritesRepository
    private weak var coordinator: LibraryCoordinator?

    init(
        watchlistRepository: WatchlistRepository = DefaultWatchlistRepository(),
        favoritesRepository: TopFavoritesRepository = DefaultTopFavoritesRepository(),
        coordinator: LibraryCoordinator? = nil
    ) {
        self.watchlistRepository = watchlistRepository
        self.favoritesRepository = favoritesRepository
        self.coordinator = coordinator
    }

    var currentItems: [LibraryMediaItem] {
        items(for: selectedFolder)
    }

    func items(for folder: LibraryFolder) -> [LibraryMediaItem] {
        let folderItems = itemsByFolder[folder] ?? []
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return folderItems }
        return folderItems.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || ($0.year?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    func selectFolder(_ folder: LibraryFolder) {
        selectedFolder = folder
    }

    func didSelectItem(_ item: LibraryMediaItem) {
        coordinator?.showMovieDetails(for: item)
    }

    func loadLibrary() {
        Task {
            let watchlist = (try? await watchlistRepository.fetchAll(list: .watchlist)) ?? []
            let watched = (try? await watchlistRepository.fetchAll(list: .watched)) ?? []
            let favorites = await favoritesRepository.fetchTopFavorites()

            let watchlistMapped = watchlist
                .filter { !$0.isUnreleased }
                .map {
                    LibraryMediaItem(
                        id: "watchlist-\($0.id.uuidString)",
                        tmdbID: $0.tmdbID,
                        title: $0.title,
                        year: $0.year,
                        releaseDate: $0.releaseDate,
                        posterPath: $0.posterPath,
                        subtitle: $0.year
                    )
                }

            let comingSoonMapped = watchlist
                .filter(\.isUnreleased)
                .map {
                    LibraryMediaItem(
                        id: "coming-soon-\($0.id.uuidString)",
                        tmdbID: $0.tmdbID,
                        title: $0.title,
                        year: $0.year,
                        releaseDate: $0.releaseDate,
                        posterPath: $0.posterPath,
                        subtitle: $0.releaseDate ?? $0.year
                    )
                }

            let seenMapped = watched.map {
                LibraryMediaItem(
                    id: "seen-\($0.id.uuidString)",
                    tmdbID: $0.tmdbID,
                    title: $0.title,
                    year: $0.year,
                    releaseDate: $0.releaseDate,
                    posterPath: $0.posterPath,
                    subtitle: $0.year
                )
            }

            let favoritesMapped = favorites.map {
                LibraryMediaItem(
                    id: "fav-\($0.id)",
                    tmdbID: $0.id,
                    title: $0.title,
                    year: $0.year,
                    posterPath: $0.posterPath,
                    subtitle: $0.year
                )
            }

            itemsByFolder[.watchlist] = watchlistMapped
            itemsByFolder[.comingSoon] = comingSoonMapped
            itemsByFolder[.favorites] = favoritesMapped
            itemsByFolder[.seen] = seenMapped
        }
    }
}
