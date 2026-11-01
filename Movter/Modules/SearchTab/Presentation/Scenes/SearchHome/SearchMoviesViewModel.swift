//
//  SearchMoviesViewModel.swift
//  Movter
//
//  Created by Nurtore on 02.05.2026.
//

import Foundation
import UIKit

final class SearchMoviesViewModel {

    enum Section {
        case browse(title: String, items: [String])
        case genres(title: String)
    }

    private let getBrowseCategoriesUseCase: GetBrowseCategoriesUseCase

    private var sections: [Section] {
        let categoryItems = getBrowseCategoriesUseCase.execute().map { $0.title }
        return [
            .browse(title: "Browse by", items: categoryItems),
            .genres(title: "Popular Genres")
        ]
    }

    init(getBrowseCategoriesUseCase: GetBrowseCategoriesUseCase = DefaultGetBrowseCategoriesUseCase()) {
        self.getBrowseCategoriesUseCase = getBrowseCategoriesUseCase
    }

    var numberOfSections: Int {
        sections.count
    }

    func section(at index: Int) -> Section? {
        sections[safe: index]
    }

    func numberOfRows(in section: Int) -> Int {
        switch sections[safe: section] {
        case let .browse(_, items): return items.count
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

    func subcategory(at indexPath: IndexPath) -> (title: String, items: [String])? {
        guard let selectedItem = item(at: indexPath),
              let items = getBrowseCategoriesUseCase.subcategory(for: selectedItem) else {
            return nil
        }
        return (selectedItem, items)
    }
}
