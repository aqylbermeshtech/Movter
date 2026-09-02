//
//  SearchPresenting.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// A screen that can raise the search field and show what comes back.
///
/// Results are pushed onto the searching screen's own stack rather than handed to the
/// Search tab, so a search started from Movies lands back in Movies — the tab you
/// searched from is the tab Back returns you to.
protocol SearchPresenting: UIViewController {}

extension SearchPresenting {

    /// Full-screen, over the floating tab bar. The chosen term comes back through
    /// `onSubmit`.
    func presentSearch() {
        let overlay = SearchOverlayViewController()
        overlay.onSubmit = { [weak self] term in
            self?.showSearchResults(for: term)
        }
        overlay.modalPresentationStyle = .fullScreen
        present(overlay, animated: true)
    }

    private func showSearchResults(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        // A previous search may have left a results screen on top; drop back to the
        // screen that searched before pushing the new one so they don't stack.
        if let nav = navigationController, nav.topViewController !== self {
            nav.popToViewController(self, animated: false)
        }

        let resultsVC = MovieGridViewController(source: .search(trimmed), title: "“\(trimmed)”")
        navigationController?.pushViewController(resultsVC, animated: true)
    }
}
