//
//  MediaListViewController.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

@MainActor
final class MediaListViewController: UIViewController {
    private let viewModel: MediaListViewModel
    private let watchlistStore: WatchlistStoring

    private let headerView = HomeHeaderView()
    private let chipsView = GenreChipsView()
    private let heroView = HeroCarouselView()
    private let trendingView = TrendingMediaGridView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private var watchlistItemIDs: [Int: UUID] = [:]

    init(
        viewModel: MediaListViewModel,
        watchlistStore: WatchlistStoring = WatchlistStoreFactory.makeStore(),
        coordinator: MoviesCoordinator? = nil
    ) {
        self.viewModel = viewModel
        self.watchlistStore = watchlistStore
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(watchlistStore: WatchlistStoring = WatchlistStoreFactory.makeStore()) {
        self.init(viewModel: MediaListViewModel(), watchlistStore: watchlistStore, coordinator: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private lazy var offlineView: OfflinePlaceholderView = {
        let view = OfflinePlaceholderView(
            message: "Trending needs a connection. It'll load as soon as you're back."
        )
        view.onRetry = { [weak self] in self?.viewModel.retry() }
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private static let heroItemCount = 5

    private lazy var actionUnavailableView: ActionUnavailablePlaceholderView = {
        let view = ActionUnavailablePlaceholderView(
            symbolName: tabActionSymbol,
            title: "Nothing to shuffle yet",
            message: "Surprise me opens a random title from what's trending, and that list hasn't arrived. Give it a moment and try again."
        )
        view.onDismiss = { [weak self] in self?.setActionUnavailableVisible(false) }
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        view.backgroundColor = .canvas
        setupUI()
        bindViewModel()
        heroView.beginLoading()
        trendingView.beginLoading()
        viewModel.fetchContent(genre: chipsView.selected)
        applyTheme()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: ThemeManager.themeDidChangeNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadWatchlist()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }

    @objc private func themeChanged() {
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(scrollView)
        view.addSubview(offlineView)
        // Last, so it covers the feed it is explaining the absence of.
        view.addSubview(actionUnavailableView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        chipsView.translatesAutoresizingMaskIntoConstraints = false
        heroView.translatesAutoresizingMaskIntoConstraints = false
        trendingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: HomeHeaderView.preferredHeight),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView(arrangedSubviews: [chipsView, heroView, trendingView])
        content.axis = .vertical
        content.spacing = 24
        content.setCustomSpacing(16, after: chipsView)
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            chipsView.heightAnchor.constraint(equalToConstant: GenreChipsView.preferredHeight),
            heroView.heightAnchor.constraint(equalToConstant: HeroCarouselView.sectionHeight),
            trendingView.heightAnchor.constraint(equalToConstant: TrendingMediaGridView.carouselSectionHeight)
        ])

        NSLayoutConstraint.activate([
            offlineView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            offlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            actionUnavailableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            actionUnavailableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionUnavailableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionUnavailableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        headerView.onSearch = { [weak self] in
            self?.presentSearch()
        }
        heroView.onMovieSelected = { [weak self] media in
            self?.showDetails(for: media)
        }
        heroView.onPlaySelected = { [weak self] media in
            self?.showDetails(for: media, revealingTrailer: true)
        }
        heroView.onWatchlistToggled = { [weak self] media in
            self?.toggleWatchlist(for: media)
        }
        trendingView.onMovieSelected = { [weak self] media in
            self?.showDetails(for: media)
        }
        trendingView.onSeeAllSelected = { [weak self] in
            self?.showSeeAll()
        }
        chipsView.onSelect = { [weak self] genre in
            guard let self = self else { return }
            self.trendingView.setSectionTitle(genre.sectionTitle)
            self.heroView.beginLoading()
            self.trendingView.beginLoading()
            self.scrollView.setContentOffset(.zero, animated: true)
            self.viewModel.fetchContent(genre: genre)
        }
    }

    private func applyTheme() {
        navigationController?.navigationBar.tintColor = .accent
        chipsView.updateTheme()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation

    private func showDetails(for media: Media, revealingTrailer: Bool = false) {
        viewModel.showMovieDetails(media: media, from: self)
    }

    private func showSeeAll() {
        let genre = viewModel.selectedGenre
        viewModel.showMovieGrid(genre: genre)
    }

    // MARK: - Watchlist

    private func loadWatchlist() {
        watchlistStore.fetchAll { [weak self] result in
            guard let self = self, case let .success(items) = result else { return }
            self.watchlistItemIDs = Dictionary(items.map { ($0.tmdbID, $0.id) }, uniquingKeysWith: { first, _ in first })
            self.heroView.setWatchlistedIDs(Set(self.watchlistItemIDs.keys))
        }
    }

    private func toggleWatchlist(for media: Media) {
        if let itemID = watchlistItemIDs[media.id] {
            watchlistStore.delete(itemID) { [weak self] result in
                guard let self = self else { return }
                guard case .success = result else {
                    self.showToast("Couldn't update your watchlist")
                    return
                }
                self.watchlistItemIDs[media.id] = nil
                self.heroView.setWatchlistedIDs(Set(self.watchlistItemIDs.keys))
                self.showToast("Removed from watchlist")
            }
        } else {
            let item = WatchlistItem(from: media)
            watchlistStore.save(item) { [weak self] result in
                guard let self = self else { return }
                guard case .success = result else {
                    self.showToast("Couldn't update your watchlist")
                    return
                }
                self.watchlistItemIDs[media.id] = item.id
                self.heroView.setWatchlistedIDs(Set(self.watchlistItemIDs.keys))
                self.showToast("Added to watchlist")
            }
        }
    }

    private func showToast(_ message: String) {
        ToastView.show(message, in: view)
    }

    // MARK: - State

    @objc private func connectivityChanged() {
        viewModel.connectivityDidChange()
    }

    private func renderOfflineState() {
        offlineView.isHidden = !viewModel.showsOfflinePlaceholder
        offlineView.setRetryAvailable(NetworkMonitor.shared.isOnline)
    }

    private func bindViewModel() {
        viewModel.onOfflineChange = { [weak self] in self?.renderOfflineState() }
        NotificationCenter.default.addObserver(
            self, selector: #selector(connectivityChanged),
            name: NetworkMonitor.connectivityDidChangeNotification, object: nil
        )
        viewModel.onUpdate = { [weak self] media in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.heroView.update(with: Array(media.prefix(Self.heroItemCount)))
                self.trendingView.update(with: media)
                self.renderOfflineState()
                self.dismissActionUnavailableIfResolved()
            }
        }
    }

    private func dismissActionUnavailableIfResolved() {
        guard !viewModel.mediaContent.isEmpty else { return }
        setActionUnavailableVisible(false)
    }

    private func setActionUnavailableVisible(_ visible: Bool) {
        let isShown = !actionUnavailableView.isHidden
        guard isShown != visible else { return }

        if visible {
            actionUnavailableView.alpha = 0
            actionUnavailableView.isHidden = false
        }
        UIView.animate(withDuration: 0.2) {
            self.actionUnavailableView.alpha = visible ? 1 : 0
        } completion: { _ in
            self.actionUnavailableView.isHidden = !visible
        }
    }
}

// MARK: - Search

extension MediaListViewController: SearchPresenting {}

// MARK: - Tab action

extension MediaListViewController: TabActionProviding {

    var tabActionSymbol: String { "shuffle" }
    var tabActionLabel: String { "Surprise me" }

    func performTabAction() {
        guard openRandomTitle() else {
            if !viewModel.showsOfflinePlaceholder {
                setActionUnavailableVisible(true)
            }
            return
        }
    }

    @discardableResult
    private func openRandomTitle() -> Bool {
        guard let media = viewModel.mediaContent.randomElement() else { return false }
        showDetails(for: media)
        return true
    }
}


// MARK: - Poster transition

extension MediaListViewController: PosterTransitionSource {
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor? {
        trendingView.transitionPoster(forMediaID: id)
    }
}
