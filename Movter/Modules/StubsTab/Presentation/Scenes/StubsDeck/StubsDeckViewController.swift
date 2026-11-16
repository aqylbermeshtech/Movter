//
//  StubsDeckViewController.swift
//  Movter
//

import SwiftUI
import UIKit

@MainActor
final class StubsDeckViewController: UIHostingController<StubsDeckView> {
    private let viewModel: StubsDeckViewModel
    private let coordinator: StubsCoordinator?

    init(viewModel: StubsDeckViewModel, coordinator: StubsCoordinator? = nil) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(rootView: StubsDeckView(viewModel: viewModel))
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
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadStubs()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

struct StubsDeckView: View {
    @ObservedObject var viewModel: StubsDeckViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.hasLoaded && viewModel.reviews.isEmpty {
                    ContentUnavailableView(
                        "No Stubs Yet",
                        systemImage: "ticket",
                        description: Text("Rate a movie to collect its cinema ticket stub.")
                    )
                    .padding(.top, 24)
                } else if !viewModel.stackedReviews.isEmpty {
                    VStack(spacing: 16) {
                        StackedStubsDeckView(
                            reviews: viewModel.stackedReviews,
                            loadArtwork: { review in
                                await viewModel.loadArtwork(for: review)
                            },
                            onTap: {
                                viewModel.didTapStack()
                            }
                        )
                        .padding(.horizontal, 16)

                        Text("\(viewModel.reviews.count) \(viewModel.reviews.count == 1 ? "TICKET" : "TICKETS") · TAP STACK TO VIEW ALL")
                            .font(Font(UIFont.microLabel))
                            .tracking(1.3)
                            .foregroundStyle(Color(uiColor: .textSecondary))
                    }
                    .padding(.top, 12)
                }

                TopFavoritesSectionView(
                    favorites: viewModel.topFavorites,
                    onAddTap: {
                        viewModel.addTopFavoriteTapped()
                    },
                    onSelectFilm: { film in
                        viewModel.didTapTopFavorite(film)
                    },
                    onRemoveTap: { id in
                        viewModel.removeTopFavorite(id: id)
                    }
                )
            }
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
    }
}
