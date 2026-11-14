//
//  StubsViewController.swift
//  Movter
//
//  Created by Nurtore on 15.11.2026.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class StubsViewModel: ObservableObject {
    @Published private(set) var reviews: [Review] = []
    @Published private(set) var hasLoaded = false

    private let fetchReviewsUseCase: FetchReviewsUseCase

    init(fetchReviewsUseCase: FetchReviewsUseCase = DefaultFetchReviewsUseCase(repository: DefaultReviewsRepository())) {
        self.fetchReviewsUseCase = fetchReviewsUseCase
    }

    func load() {
        Task {
            do {
                reviews = try await fetchReviewsUseCase.execute()
            } catch {
                reviews = []
            }
            hasLoaded = true
        }
    }
}

@MainActor
final class StubsViewController: UIHostingController<StubsView> {

    private let viewModel: StubsViewModel

    init(viewModel: StubsViewModel? = nil) {
        let vm = viewModel ?? StubsViewModel()
        self.viewModel = vm
        super.init(rootView: StubsView(viewModel: vm))
        title = "Stubs"
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        navigationController?.navigationBar.prefersLargeTitles = true
        rootView.onSelect = { [weak self] review in
            let ticketVC = TicketViewController(review: review)
            self?.present(UINavigationController(rootViewController: ticketVC), animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }
}

struct StubsView: View {
    @ObservedObject var viewModel: StubsViewModel
    var onSelect: ((Review) -> Void)?

    var body: some View {
        Group {
            if viewModel.hasLoaded && viewModel.reviews.isEmpty {
                ContentUnavailableView(
                    "No Stubs Yet",
                    systemImage: "ticket",
                    description: Text("Rate a movie to collect its cinema ticket stub.")
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.reviews, id: \.id) { review in
                            StubRowView(review: review)
                                .onTapGesture {
                                    onSelect?(review)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
        .navigationTitle("Stubs")
    }
}

private struct StubRowView: View {
    let review: Review

    @State private var posterImage: UIImage?
    @State private var logoImage: UIImage?

    var body: some View {
        TicketStubView(
            review: review,
            posterImage: posterImage,
            logoImage: logoImage
        )
        .task(id: review.id) {
            async let poster = loadImage(from: review.posterURL)
            async let logo = loadTitleLogo()
            posterImage = await poster
            logoImage = await logo
        }
    }

    private func loadTitleLogo() async -> UIImage? {
        guard let tmdbID = review.tmdbID else { return nil }
        let artwork = await TMDBService.shared.fetchHeroArtwork(for: tmdbID, type: .movie)
        guard !Task.isCancelled,
              let logoPath = artwork.logoPath,
              let logoURL = TMDBImageURL.url(path: logoPath, width: .poster) else {
            return nil
        }
        return await loadImage(from: logoURL)
    }

    private func loadImage(from url: URL?) async -> UIImage? {
        guard let url else { return nil }
        return await withCheckedContinuation { continuation in
            ImageLoader.load(url: url) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
