//
//  SeenFilmsLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation
import FirebaseAuth

protocol SeenFilmsLocalDataSource: AnyObject {
    func loadSeenIDs() -> Set<Int>
    func saveSeenIDs(_ ids: Set<Int>)
}

final class UserDefaultsSeenFilmsDataSource: SeenFilmsLocalDataSource {

    private let userIDProvider: () -> String?
    private let defaults: UserDefaults

    private var defaultsKey: String {
        let userID = userIDProvider() ?? "local"
        return "com.nurtore.movter.seenFilms.\(userID)"
    }

    init(
        defaults: UserDefaults = .standard,
        userIDProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.defaults = defaults
        self.userIDProvider = userIDProvider
    }

    func loadSeenIDs() -> Set<Int> {
        Set(defaults.array(forKey: defaultsKey) as? [Int] ?? [])
    }

    func saveSeenIDs(_ ids: Set<Int>) {
        defaults.set(Array(ids), forKey: defaultsKey)
    }
}

