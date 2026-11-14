//
//  StubsListViewController.swift
//  Movter
//

import SwiftUI
import UIKit

@MainActor
final class StubsListViewController: UIHostingController<StubsListView> {
    private let viewModel: StubsListViewModel
    private let coordinator: StubsCoordinator?

    init(viewModel: StubsListViewModel, coordinator: StubsCoordinator? = nil) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(rootView: StubsListView(viewModel: viewModel))
        title = "All Tickets"
        navigationItem.largeTitleDisplayMode = .never
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableInteractivePopGesture()
        viewModel.loadStubs()
    }
}

struct StubsListView: View {
    @ObservedObject var viewModel: StubsListViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 18) {
                ForEach(viewModel.reviews, id: \.id) { review in
                    StubListItemView(
                        review: review,
                        loadArtwork: { item in
                            await viewModel.loadArtwork(for: item)
                        },
                        onSelect: {
                            viewModel.didSelectStub(review)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
        .navigationTitle("All Tickets")
    }
}

private struct StubListItemView: View {
    let review: Review
    let loadArtwork: (Review) async -> (poster: UIImage?, logo: UIImage?)
    let onSelect: () -> Void

    @State private var posterImage: UIImage?
    @State private var logoImage: UIImage?

    var body: some View {
        Button(action: onSelect) {
            TicketStubView(
                review: review,
                posterImage: posterImage,
                logoImage: logoImage
            )
        }
        .buttonStyle(.plain)
        .task(id: review.id) {
            let result = await loadArtwork(review)
            posterImage = result.poster
            logoImage = result.logo
        }
    }
}
