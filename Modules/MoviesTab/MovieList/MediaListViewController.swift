//
//  MediaListViewController.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit
import SafariServices

final class MediaListViewController: UIViewController {
    private let viewModel = MediaListViewModel()
    private let heroView = HeroCarouselView()
    private let trendingView = TrendingMediaGridView()
    private let posterTransition = PosterTransitionController()
    private let topSwitcher = TopSegmentedControlView()

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
        trendingView.beginLoading(showingArticles: false)
        viewModel.fetchContent(type: .movies)
        applyTheme()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: ThemeManager.themeDidChangeNotification,
            object: nil
        )
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Movter"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .textPrimary
    }
    
    @objc private func themeChanged() {
        // Обновляем UI в главном потоке
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }
    
    /// The carousel is a fixed-height section; articles still scroll to the bottom.
    /// Exactly one of these is active at a time.
    private var trendingHeight: NSLayoutConstraint!
    private var trendingBottom: NSLayoutConstraint!

    /// Zero-height and hidden for the articles tab, which has no backdrop art to show.
    private var heroHeight: NSLayoutConstraint!

    private func setupUI() {
        view.addSubview(topSwitcher)
        view.addSubview(heroView)
        view.addSubview(trendingView)
        view.addSubview(offlineView)
        // Last, so it covers the feed it is explaining the absence of.
        view.addSubview(actionUnavailableView)

        topSwitcher.translatesAutoresizingMaskIntoConstraints = false
        heroView.translatesAutoresizingMaskIntoConstraints = false
        trendingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topSwitcher.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topSwitcher.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSwitcher.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            heroView.topAnchor.constraint(equalTo: topSwitcher.bottomAnchor, constant: 10),
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            trendingView.topAnchor.constraint(equalTo: heroView.bottomAnchor, constant: 10),
            trendingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trendingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            offlineView.topAnchor.constraint(equalTo: topSwitcher.bottomAnchor),
            offlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Same footprint as the offline placeholder: the content area below the
        // segmented control, leaving the switcher reachable.
        NSLayoutConstraint.activate([
            actionUnavailableView.topAnchor.constraint(equalTo: topSwitcher.bottomAnchor),
            actionUnavailableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionUnavailableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionUnavailableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        heroHeight = heroView.heightAnchor.constraint(equalToConstant: HeroCarouselView.sectionHeight)
        heroHeight.isActive = true

        trendingHeight = trendingView.heightAnchor.constraint(
            equalToConstant: TrendingMediaGridView.carouselSectionHeight
        )
        trendingBottom = trendingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        setTrendingFillsScreen(false)
        heroView.onMovieSelected = { [weak self] media in
            let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        trendingView.onMovieSelected = { [weak self] media in
            guard let self = self else { return }
            let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
            self.posterTransition.push(detailVC, for: media, from: self)
        }
        trendingView.onArticleSelected = { [weak self] article in
            guard let url = self?.viewModel.getUrl(for: article) else { return }
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = .accent
            self?.present(safariVC, animated: true)
        }
        topSwitcher.onSelect = { [weak self] type in
            guard let self = self else { return }
            self.trendingView.setSectionTitle(type.sectionTitle)
            self.setTrendingFillsScreen(type == .articles)
            self.setHeroVisible(type != .articles)
            if type != .articles {
                self.heroView.beginLoading()
            }
            self.trendingView.beginLoading(showingArticles: type == .articles)
            self.viewModel.fetchContent(type: type)
        }
    }

    private func setHeroVisible(_ visible: Bool) {
        heroView.isHidden = !visible
        heroHeight.constant = visible ? HeroCarouselView.sectionHeight : 0
    }
    
    private func applyTheme() {
        navigationController?.navigationBar.tintColor = .accent
        topSwitcher.updateTheme(with: .accent)
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setTrendingFillsScreen(_ fills: Bool) {
        trendingHeight.isActive = !fills
        trendingBottom.isActive = fills
    }

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
        viewModel.onUpdate = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .media(let media):
                    self?.heroView.update(with: Array(media.prefix(Self.heroItemCount)))
                    self?.trendingView.update(with: media)
                case .articles(let articles):
                    self?.trendingView.updateArticles(with: articles)
                }
                self?.renderOfflineState()
                self?.dismissActionUnavailableIfResolved()
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
        let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
        navigationController?.pushViewController(detailVC, animated: true)
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
