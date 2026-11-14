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
        title = "Stubs"
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadStubs()
    }
}

struct StubsDeckView: View {
    @ObservedObject var viewModel: StubsDeckViewModel

    var body: some View {
        Group {
            if viewModel.hasLoaded && viewModel.reviews.isEmpty {
                ContentUnavailableView(
                    "No Stubs Yet",
                    systemImage: "ticket",
                    description: Text("Rate a movie to collect its cinema ticket stub.")
                )
            } else if !viewModel.stackedReviews.isEmpty {
                VStack(spacing: 24) {
                    Spacer()

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

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
        .navigationTitle("Stubs")
    }
}
