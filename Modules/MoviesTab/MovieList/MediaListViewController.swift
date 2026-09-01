//
//  MediaListViewController.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

final class MediaListViewController: UIViewController {
    private let viewModel = MediaListViewModel()
    private let watchlistStore: WatchlistStoring

    private let headerView = HomeHeaderView()
    private let chipsView = GenreChipsView()
    private let heroView = HeroCarouselView()
    private let trendingView = TrendingMediaGridView()
    private let posterTransition = PosterTransitionController()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    /// The user's saved titles, by TMDB id, so the hero's eye button knows which way
    /// round it is and the toggle knows which stored item to delete.
    private var watchlistItemIDs: [Int: UUID] = [:]

    init(watchlistStore: WatchlistStoring) {
        self.watchlistStore = watchlistStore
        super.init(nibName: nil, bundle: nil)
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
    /// Only the first handful feed the banner; the row below still shows the full list.
    private static let heroItemCount = 5

    /// Explains why "Surprise me" did nothing, on the occasions it can't run.
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
        // The header stands in for the bar here; the rest of the tab still uses it.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // The watchlist also changes from the swipe deck and the watchlist screen.
        loadWatchlist()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    /// Home draws its own header, but the appearance is the whole tab's — the screens
    /// pushed from here inherit it.
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
        view.addSubview(chipsView)
        view.addSubview(scrollView)
        view.addSubview(offlineView)
        // Last, so it covers the feed it is explaining the absence of.
        view.addSubview(actionUnavailableView)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        chipsView.translatesAutoresizingMaskIntoConstraints = false
        heroView.translatesAutoresizingMaskIntoConstraints = false
        trendingView.translatesAutoresizingMaskIntoConstraints = false

        // The header and chips stay put; only the feed under them scrolls, so the
        // filter is always one tap away however far down the row you are.
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: HomeHeaderView.preferredHeight),

            chipsView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            chipsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipsView.heightAnchor.constraint(equalToConstant: GenreChipsView.preferredHeight),

            scrollView.topAnchor.constraint(equalTo: chipsView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView(arrangedSubviews: [heroView, trendingView])
        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            heroView.heightAnchor.constraint(equalToConstant: HeroCarouselView.sectionHeight),
            trendingView.heightAnchor.constraint(equalToConstant: TrendingMediaGridView.carouselSectionHeight)
        ])

        NSLayoutConstraint.activate([
            offlineView.topAnchor.constraint(equalTo: chipsView.bottomAnchor),
            offlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Same footprint as the offline placeholder: the content area below the chips,
        // leaving the filter reachable.
        NSLayoutConstraint.activate([
            actionUnavailableView.topAnchor.constraint(equalTo: chipsView.bottomAnchor),
            actionUnavailableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionUnavailableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionUnavailableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        headerView.onSearch = { [weak self] in
            self?.showSearchTab()
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
            guard let self = self else { return }
            let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
            self.posterTransition.push(detailVC, for: media, from: self)
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
        let detailVC = MediaDetailsViewController(
            viewModel: MediaDetailsViewModel(media: media),
            revealsTrailer: revealingTrailer
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    /// The whole feed for the current chip, as a grid. The row is a sample of it, so
    /// this opens the same query rather than a related one.
    private func showSeeAll() {
        let genre = viewModel.selectedGenre
        let gridVC = MovieGridViewController(
            source: .discover(genre.query),
            title: genre.sectionTitle
        )
        navigationController?.pushViewController(gridVC, animated: true)
    }

    private func showSearchTab() {
        (navigationController?.parent as? MainTabBarController)?
            .selectTab(titled: MainTabBarFactory.searchTabTitle)
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
        // No `bottomInset`: the screen already carries the floating bar's clearance as
        // an additional safe-area inset, which is what the pill anchors itself to.
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

    /// The explanation is only true while the feed is empty; once it fills, it goes.
    private func dismissActionUnavailableIfResolved() {
        guard !viewModel.mediaContent.isEmpty else { return }
        setActionUnavailableVisible(false)
    }

    /// Fades rather than snaps. It appears in response to a tap, and swapping the whole
    /// content area instantly reads as the screen having navigated somewhere.
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

// MARK: - Tab action

extension MediaListViewController: TabActionProviding {

    var tabActionSymbol: String { "shuffle" }
    var tabActionLabel: String { "Surprise me" }

    /// Opens a random title from whatever's currently trending — a way into the
    /// catalogue for someone browsing without anything particular in mind.
    func performTabAction() {
        guard openRandomTitle() else {
            // Nothing to pick from. Say so, rather than letting the button appear broken
            // — except when the offline placeholder is already up, since it explains the
            // same emptiness and carries a retry this one can't offer.
            if !viewModel.showsOfflinePlaceholder {
                setActionUnavailableVisible(true)
            }
            return
        }
    }

    /// - Returns: false when the feed is still empty, so the caller can queue the tap.
    @discardableResult
    private func openRandomTitle() -> Bool {
        guard let media = viewModel.mediaContent.randomElement() else { return false }
        // Plain push: the title is picked at random, so there's no tapped poster for it
        // to grow out of.
        showDetails(for: media)
        return true
    }
}


// MARK: - Poster transition

extension MediaListViewController: PosterTransitionSource {

    /// Only the trending row flies its artwork into the details screen; the hero banner
    /// pushes plainly, so there is only one carousel to search.
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor? {
        trendingView.transitionPoster(forMediaID: id)
    }
}
