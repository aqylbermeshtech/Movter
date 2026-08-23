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
    private let topSwitcher = TopSegmentedControlView()
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

        heroHeight = heroView.heightAnchor.constraint(equalToConstant: HeroCarouselView.sectionHeight)
        heroHeight.isActive = true

        trendingHeight = trendingView.heightAnchor.constraint(
            equalToConstant: TrendingMediaGridView.carouselSectionHeight
        )
        trendingBottom = trendingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        setTrendingFillsScreen(false)
        heroView.onMovieSelected = { [weak self] media in
            let detailVM = MediaDetailsViewModel(media: media)
            let detailVC = MediaDetailsViewController(viewModel: detailVM)
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        trendingView.onMovieSelected = { [weak self] media in
            let detailVM = MediaDetailsViewModel(media: media)
            let detailVC = MediaDetailsViewController(viewModel: detailVM)
            self?.navigationController?.pushViewController(detailVC, animated: true)
        }
        trendingView.onArticleSelected = { [weak self] article in
            guard let url = self?.viewModel.getUrl(for: article) else { return }
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = .accent
            self?.present(safariVC, animated: true)
        }
        topSwitcher.onSegmentChanged = { [weak self] index in
            guard let self = self, let type = ContentType(rawValue: index) else { return }
            switch type {
            case .movies:
                self.trendingView.setSectionTitle("Trending Movies")
            case .tvSeries:
                self.trendingView.setSectionTitle("Trending TV Shows")
            case .articles:
                self.trendingView.setSectionTitle("Latest Film News")
            }
            self.setTrendingFillsScreen(type == .articles)
            self.setHeroVisible(type != .articles)
            if type != .articles {
                self.heroView.beginLoading()
            }
            self.trendingView.beginLoading(showingArticles: type == .articles)
            self.viewModel.fetchContent(type: type)
            self.trendingView.setSectionTitle(self.viewModel.sectionTitle)
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

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .media(let media):
                    self?.heroView.update(with: Array(media.prefix(Self.heroItemCount)))
                    self?.trendingView.update(with: media)
                case .articles(let articles):
                    self?.trendingView.updateArticles(with: articles)
                }
            }
        }
    }
}
