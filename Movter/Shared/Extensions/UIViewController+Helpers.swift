//
//  UIViewController+Helpers.swift
//  Movter
//
//  Created by Nurtore on 13.11.2026.
//

import UIKit

extension UIViewController {

    /// Presents a simple single-button "OK" alert.
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// Configures an opaque `.canvas` navigation bar appearance with `.textPrimary` titles.
    func configureOpaqueNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }
}
