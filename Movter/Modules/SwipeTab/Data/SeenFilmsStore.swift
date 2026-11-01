//
//  SeenFilmsStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation

protocol SeenFilmsStoring: AnyObject {
    func fetchIDs(completion: @escaping (Set<Int>) -> Void)
    func markSeen(_ tmdbID: Int)
}

enum SeenFilmsStoreFactory {
    static func makeStore() -> SeenFilmsStoring {
        LocalSeenFilmsStore()
    }
}

final class LocalSeenFilmsStore: SeenFilmsStoring {

    private let repository: SeenFilmsRepository

    init(repository: SeenFilmsRepository = DefaultSeenFilmsRepository()) {
        self.repository = repository
    }

    func fetchIDs(completion: @escaping (Set<Int>) -> Void) {
        let ids = repository.fetchSeenIDs()
        DispatchQueue.main.async { completion(ids) }
    }

    func markSeen(_ tmdbID: Int) {
        repository.markSeen(tmdbID: tmdbID)
    }
}
