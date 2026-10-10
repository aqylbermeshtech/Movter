//
//  SeenFilmsStore.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import Foundation
import FirebaseAuth

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

    private let userIDProvider: () -> String?
    private let defaults = UserDefaults.standard

    private var defaultsKey: String {
        let userID = userIDProvider() ?? "local"
        return "com.nurtore.movter.seenFilms.\(userID)"
    }

    init(userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.userIDProvider = userIDProvider
    }

    convenience init(userID: String?) {
        self.init(userIDProvider: { userID })
    }

    func fetchIDs(completion: @escaping (Set<Int>) -> Void) {
        completion(readIDs())
    }

    func markSeen(_ tmdbID: Int) {
        var ids = readIDs()
        guard ids.insert(tmdbID).inserted else { return }
        defaults.set(Array(ids), forKey: defaultsKey)
    }

    private func readIDs() -> Set<Int> {
        Set(defaults.array(forKey: defaultsKey) as? [Int] ?? [])
    }
}
