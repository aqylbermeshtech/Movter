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
        let theme = ThemeManager.shared.currentTheme
        navigationController?.navigationBar.tintColor = theme.mainColor
        topSwitcher.updateTheme(with: theme.mainColor)
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
            }
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
        // Empty only before the first load lands; the articles segment leaves the last
        // media list in place, so there's still something to pick from there.
        guard let media = viewModel.mediaContent.randomElement() else { return }
        // Plain push: the title is picked at random, so there's no tapped poster for it
        // to grow out of.
        let detailVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
        navigationController?.pushViewController(detailVC, animated: true)
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
