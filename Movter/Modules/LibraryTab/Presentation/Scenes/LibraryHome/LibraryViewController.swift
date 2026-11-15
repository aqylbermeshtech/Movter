//
//  LibraryViewController.swift
//  Movter
//

import SwiftUI
import UIKit

@MainActor
final class LibraryViewController: UIHostingController<LibraryView> {
    private let coordinator: LibraryCoordinator?

    init(coordinator: LibraryCoordinator? = nil) {
        self.coordinator = coordinator
        super.init(rootView: LibraryView())
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Shows"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .canvas
    }
}

struct LibraryView: View {
    var body: some View {
        ContentUnavailableView(
            "Library",
            systemImage: "books.vertical",
            description: Text("Your saved films and collections will appear here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .canvas))
    }
}
