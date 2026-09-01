//
//  TrendingMoviesGridView.swift
//  Movter
//
//  Created by Nurtore on 01.05.2026.
//

import UIKit

final class TrendingMediaGridView: UIView {
    var onMovieSelected: ((Media) -> Void)?
    var onArticleSelected: ((Article) -> Void)?
    private var movies: [Media] = []
    private var articles: [Article] = []
    private var isShowingArticles: Bool = false
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Trending Movies"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Poster width in the carousel; everything else derives from it.
    private static let itemWidth: CGFloat = 140
    /// Posters only — TMDB artwork is 2:3, so no caption means no spare height.
    private static let itemHeight: CGFloat = itemWidth * 1.5
    private static let titleHeight: CGFloat = 28
    private static let horizontalInset: CGFloat = 16

    /// Height this view needs when it's showing the media carousel. Articles still
    /// scroll vertically and take whatever height they're given.
    static var carouselSectionHeight: CGFloat { titleHeight + 10 + itemHeight }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        cv.register(ArticlesCell.self, forCellWithReuseIdentifier: "ArticleCell")
        cv.backgroundColor = .clear
        cv.isScrollEnabled = true
        cv.showsHorizontalScrollIndicator = false
        // Cells scroll out under the screen edges rather than stopping short of them.
        cv.contentInset = UIEdgeInsets(top: 0, left: Self.horizontalInset, bottom: 0, right: Self.horizontalInset)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let skeletonView = SkeletonGridView(style: .carousel(itemWidth: itemWidth))

    /// Call when a fetch is issued; `update(with:)` / `updateArticles(with:)` end it.
    /// The mode is passed in because the skeleton has to promise the right shape
    /// before the response arrives to tell us what shape that is — and because the
    /// old content (still the other type, still the other scroll direction) has to
    /// go now too, or it sits under the skeleton until the new data lands.
    func beginLoading(showingArticles: Bool) {
        isShowingArticles = showingArticles
        movies = []
        articles = []
        setScrollDirection(showingArticles ? .vertical : .horizontal)
        collectionView.reloadData()

        skeletonView.setStyle(showingArticles ? .articles : .carousel(itemWidth: Self.itemWidth))
        skeletonView.beginLoading()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .canvas
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skeletonView)
        NSLayoutConstraint.activate([
            skeletonView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])
    }

    func update(with movies: [Media]) {
        self.isShowingArticles = false
        self.movies = movies
        setScrollDirection(.horizontal)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.skeletonView.endLoading()
        }
    }

    func updateArticles(with articles: [Article]) {
        self.isShowingArticles = true
        self.articles = articles
        setScrollDirection(.vertical)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.skeletonView.endLoading()
        }
    }
    
    private func setScrollDirection(_ direction: UICollectionView.ScrollDirection) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              layout.scrollDirection != direction else { return }
        layout.scrollDirection = direction
        collectionView.setContentOffset(
            CGPoint(x: direction == .horizontal ? -Self.horizontalInset : 0, y: 0),
            animated: false
        )
        layout.invalidateLayout()
    }

    func setSectionTitle(_ title: String) {
        UIView.transition(with: titleLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = title
        }, completion: nil)
    }
}

extension TrendingMediaGridView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isShowingArticles ? articles.count : movies.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isShowingArticles {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCell", for: indexPath) as! ArticlesCell
            let article = articles[indexPath.item]
            cell.configure(with: article)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as! MediaCell
            let media = movies[indexPath.item]
            cell.configure(with: media, showsCaption: false)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isShowingArticles {
            return CGSize(width: collectionView.frame.width - Self.horizontalInset * 2, height: 380)
        }
        return CGSize(width: Self.itemWidth, height: Self.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isShowingArticles {
            onArticleSelected?(articles[indexPath.item])
        } else {
            onMovieSelected?(movies[indexPath.item])
        }
    }
}

// MARK: - Poster transition

extension TrendingMediaGridView {

    /// The poster `id` is showing in this carousel, if it's scrolled into view. Nil while
    /// the articles segment is up: the indices then address `articles`, and the cells
    /// aren't posters at all.
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor? {
        guard !isShowingArticles else { return nil }
        return collectionView.mediaPosterAnchor(forMediaID: id) { [weak self] index in
            self?.movies[safe: index]?.id
        }
    }
}
