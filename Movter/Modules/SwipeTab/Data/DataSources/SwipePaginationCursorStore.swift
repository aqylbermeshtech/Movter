//
//  SwipePaginationCursorStore.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

protocol SwipePaginationCursorStoring {
    func loadPageCursor() -> Int
    func savePageCursor(_ page: Int)
}

final class UserDefaultsSwipePaginationCursorStore: SwipePaginationCursorStoring {

    static let defaultPage = 1
    static let maxPage = 500

    private let defaults: UserDefaults
    private let userIDProvider: () -> String?

    private var defaultsKey: String {
        let userID = userIDProvider() ?? "local"
        return "com.nurtore.movter.swipePageCursor.\(userID)"
    }

    init(
        defaults: UserDefaults = .standard,
        userIDProvider: @escaping () -> String? = { nil }
    ) {
        self.defaults = defaults
        self.userIDProvider = userIDProvider
    }

    func loadPageCursor() -> Int {
        Self.normalizedPage(defaults.integer(forKey: defaultsKey))
    }

    func savePageCursor(_ page: Int) {
        defaults.set(Self.normalizedPage(page), forKey: defaultsKey)
    }

    private static func normalizedPage(_ page: Int) -> Int {
        if page < defaultPage || page > maxPage {
            return defaultPage
        }
        return page
    }
}
