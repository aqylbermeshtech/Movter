//
//  LibraryViewModel.swift
//  Movter
//

import Combine
import Foundation
import SwiftUI

enum LibraryFolder: String, CaseIterable, Identifiable {
    case upNext
    case watchlist
    case favorites
    case finished
    case stopped

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upNext: return "Up Next"
        case .watchlist: return "Watchlist"
        case .favorites: return "Favorites"
        case .finished: return "Finished"
        case .stopped: return "Stopped"
        }
    }

    var symbol: String {
        switch self {
        case .upNext: return "play.circle.fill"
        case .watchlist: return "bookmark.fill"
        case .favorites: return "heart.fill"
        case .finished: return "checkmark.seal.fill"
        case .stopped: return "archivebox.fill"
        }
    }

    var activeColor: Color {
        switch self {
        case .upNext:
            return Color(red: 0.95, green: 0.83, blue: 0.04)
        case .watchlist:
            return Color(red: 0.62, green: 0.31, blue: 0.96)
        case .favorites:
            return Color(red: 0.92, green: 0.24, blue: 0.28)
        case .finished:
            return Color(red: 0.18, green: 0.78, blue: 0.38)
        case .stopped:
            return Color(red: 0.45, green: 0.45, blue: 0.49)
        }
    }
}

struct LibraryMediaItem: Identifiable, Equatable {
    let id: String
    let tmdbID: Int
    let title: String
    let year: String?
    let posterPath: String?
    let subtitle: String?

    var posterURL: URL? {
        TMDBImageURL.url(path: posterPath, width: .poster)
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedFolder: LibraryFolder = .upNext
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
        let folderItems = itemsByFolder[selectedFolder] ?? []
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

    func loadLibrary() {
        Task {
            let watchlist = (try? await watchlistRepository.fetchAll(list: .watchlist)) ?? []
            let watched = (try? await watchlistRepository.fetchAll(list: .watched)) ?? []
            let favorites = await favoritesRepository.fetchTopFavorites()

            let watchlistMapped = watchlist.map {
                LibraryMediaItem(
                    id: "watchlist-\($0.id.uuidString)",
                    tmdbID: $0.tmdbID,
                    title: $0.title,
                    year: $0.year,
                    posterPath: $0.posterPath,
                    subtitle: $0.year
                )
            }

            let finishedMapped = watched.map {
                LibraryMediaItem(
                    id: "finished-\($0.id.uuidString)",
                    tmdbID: $0.tmdbID,
                    title: $0.title,
                    year: $0.year,
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

            itemsByFolder[.upNext] = Array(watchlistMapped.prefix(6))
            itemsByFolder[.watchlist] = watchlistMapped
            itemsByFolder[.favorites] = favoritesMapped
            itemsByFolder[.finished] = finishedMapped
            if itemsByFolder[.stopped] == nil {
                itemsByFolder[.stopped] = []
            }
        }
    }
}
