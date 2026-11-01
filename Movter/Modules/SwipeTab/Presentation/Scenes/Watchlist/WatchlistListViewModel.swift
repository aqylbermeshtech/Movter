//
//  WatchlistListViewModel.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

final class WatchlistListViewModel {

    typealias Presentation = WatchlistPresentationType

    let presentation: WatchlistPresentationType

    var onChange: (() -> Void)?
    var onError: ((String) -> Void)?

    private let fetchWatchlistUseCase: FetchWatchlistUseCase
    private let deleteWatchlistItemUseCase: DeleteWatchlistItemUseCase
    private(set) var items: [WatchlistItem] = []

    init(
        presentation: WatchlistPresentationType = .watchlist,
        fetchWatchlistUseCase: FetchWatchlistUseCase = DefaultFetchWatchlistUseCase(),
        deleteWatchlistItemUseCase: DeleteWatchlistItemUseCase = DefaultDeleteWatchlistItemUseCase()
    ) {
        self.presentation = presentation
        self.fetchWatchlistUseCase = fetchWatchlistUseCase
        self.deleteWatchlistItemUseCase = deleteWatchlistItemUseCase
    }

    convenience init(
        store: WatchlistStoring,
        presentation: WatchlistPresentationType = .watchlist
    ) {
        self.init(
            presentation: presentation,
            fetchWatchlistUseCase: DefaultFetchWatchlistUseCase(),
            deleteWatchlistItemUseCase: DefaultDeleteWatchlistItemUseCase()
        )
    }

    var isEmpty: Bool { items.isEmpty }

    func load() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let fetched = try await self.fetchWatchlistUseCase.execute(list: self.presentation)
                await MainActor.run {
                    self.items = fetched
                    self.onChange?()
                }
            } catch {
                await MainActor.run {
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    func item(at indexPath: IndexPath) -> WatchlistItem? {
        items[safe: indexPath.row]
    }

    func delete(at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        guard let item = item(at: indexPath) else {
            completion(false)
            return
        }
        items.remove(at: indexPath.row)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.deleteWatchlistItemUseCase.execute(id: item.id, from: self.presentation)
                await MainActor.run {
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    self.onError?(error.localizedDescription)
                    self.load()
                    completion(false)
                }
            }
        }
    }
}
