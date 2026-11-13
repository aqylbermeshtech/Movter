//
//  HeroCarouselView.swift
//  Movter
//
//  Created by Nurtore on 23.08.2026.
//

import UIKit

final class HeroCarouselView: UIView {
    var onMovieSelected: ((Media) -> Void)?
    var onPlaySelected: ((Media) -> Void)?
    var onWatchlistToggled: ((Media) -> Void)?

    private var items: [Media] = []
    private var watchlistedIDs: Set<Int> = []

    private static let horizontalInset: CGFloat = 16

    static let imageAspect: CGFloat = 1.48
    private static let pageControlHeight: CGFloat = 16
    private static let pageControlSpacing: CGFloat = 14

    static var sectionHeight: CGFloat {
        let itemWidth = UIScreen.main.bounds.width - horizontalInset * 2
        return (itemWidth * imageAspect) + pageControlSpacing + pageControlHeight
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(HeroCarouselCell.self, forCellWithReuseIdentifier: HeroCarouselCell.identifier)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let pageIndicator = PageIndicatorView()

    private let skeletonView = SkeletonGridView(
        style: .hero(itemWidth: UIScreen.main.bounds.width - HeroCarouselView.horizontalInset * 2)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        addSubview(collectionView)
        addSubview(pageIndicator)
        collectionView.delegate = self
        collectionView.dataSource = self
        pageIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: Self.imageAspect,
                constant: -Self.horizontalInset * 2 * Self.imageAspect
            ),

            pageIndicator.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Self.pageControlSpacing),
            pageIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageIndicator.heightAnchor.constraint(equalToConstant: Self.pageControlHeight)
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

    func beginLoading() {
        skeletonView.beginLoading()
    }

    func update(with items: [Media]) {
        self.items = items
        pageIndicator.numberOfPages = items.count
        pageIndicator.currentPage = 0
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.collectionView.setContentOffset(.zero, animated: false)
            self.skeletonView.endLoading()
        }
    }

    func setWatchlistedIDs(_ ids: Set<Int>) {
        guard ids != watchlistedIDs else { return }
        watchlistedIDs = ids
        for case let cell as HeroCarouselCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let media = items[safe: indexPath.item] else { continue }
            cell.setWatchlisted(ids.contains(media.id))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize.width != bounds.width {
            layout.itemSize = CGSize(width: bounds.width, height: collectionView.bounds.height)
            layout.invalidateLayout()
        }
    }
}

extension HeroCarouselView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeroCarouselCell.identifier, for: indexPath) as! HeroCarouselCell
        let media = items[indexPath.item]
        cell.configure(with: media, isWatchlisted: watchlistedIDs.contains(media.id))
        cell.onPlay = { [weak self] in self?.onPlaySelected?(media) }
        cell.onWatchlist = { [weak self] in self?.onWatchlistToggled?(media) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onMovieSelected?(items[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        pageIndicator.currentPage = max(0, min(page, items.count - 1))
    }
}

final class PageIndicatorView: UIView {

    private static let dotSize: CGFloat = 6
    private static let currentWidth: CGFloat = 22
    private static let spacing: CGFloat = 6

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = PageIndicatorView.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var dots: [UIView] = []
    private var widths: [NSLayoutConstraint] = []

    var numberOfPages: Int = 0 {
        didSet {
            guard numberOfPages != oldValue else { return }
            rebuild()
        }
    }

    var currentPage: Int = 0 {
        didSet {
            guard currentPage != oldValue else { return }
            applySelection(animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func rebuild() {
        dots.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        dots = []
        widths = []

        guard numberOfPages > 1 else { return }

        for _ in 0..<numberOfPages {
            let dot = UIView()
            dot.layer.cornerRadius = Self.dotSize / 2
            dot.layer.cornerCurve = .continuous
            dot.translatesAutoresizingMaskIntoConstraints = false
            let width = dot.widthAnchor.constraint(equalToConstant: Self.dotSize)
            NSLayoutConstraint.activate([
                width,
                dot.heightAnchor.constraint(equalToConstant: Self.dotSize)
            ])
            stack.addArrangedSubview(dot)
            dots.append(dot)
            widths.append(width)
        }
        applySelection(animated: false)
    }

    private func applySelection(animated: Bool) {
        let apply = {
            for (index, dot) in self.dots.enumerated() {
                let isCurrent = index == self.currentPage
                self.widths[index].constant = isCurrent ? Self.currentWidth : Self.dotSize
                dot.backgroundColor = isCurrent ? .accent : .hairline
            }
            self.layoutIfNeeded()
        }
        guard animated else {
            apply()
            return
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) { apply() }
    }
}

final class HeroCarouselCell: UICollectionViewCell {
    static let identifier = "HeroCarouselCell"

    var onPlay: (() -> Void)?
    var onWatchlist: (() -> Void)?

    private static let sideInset: CGFloat = 16
    private static let contentInset: CGFloat = 18

    private var mediaID: Int?
    private var posterTask: Task<Void, Never>?

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.layer.cornerCurve = .continuous
        iv.backgroundColor = .surface
        iv.tintColor = .textSecondary
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let scrimView = GradientView(
        colors: [
            .clear,
            UIColor.black.withAlphaComponent(0.55),
            UIColor.black.withAlphaComponent(0.92)
        ],
        locations: [0, 0.5, 1]
    )

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let fallbackTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .screenTitle
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .movter(size: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.68)
        label.textAlignment = .center
        return label
    }()

    private lazy var playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.titleLineBreakMode = .byTruncatingTail
        config.image = UIImage(
            systemName: "play.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        )
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 18)
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.attributedTitle = AttributedString(
            "Play",
            attributes: AttributeContainer([.font: UIFont.movter(size: 14, weight: .semibold)])
        )
        let button = UIButton(configuration: config)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(UIAction { [weak self] _ in self?.onPlay?() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var watchlistButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.titleLineBreakMode = .byTruncatingTail
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 16)
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.55)
        config.baseForegroundColor = .white
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.22)
        config.background.strokeWidth = 1
        let button = UIButton(configuration: config)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addAction(UIAction { [weak self] _ in self?.onWatchlist?() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.addSubview(scrimView)

        let actions = UIStackView(arrangedSubviews: [watchlistButton, playButton])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.alignment = .center

        let stack = UIStackView(arrangedSubviews: [logoImageView, fallbackTitleLabel, metaLabel, actions])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(8, after: logoImageView)
        stack.setCustomSpacing(8, after: fallbackTitleLabel)
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrimView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.sideInset),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.sideInset),

            logoImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 240),
            logoImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 76),

            stack.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: Self.contentInset),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -Self.contentInset),
            stack.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -Self.contentInset),

            scrimView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            scrimView.topAnchor.constraint(equalTo: stack.topAnchor, constant: -72)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterTask?.cancel()
        posterTask = nil
        mediaID = nil
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        logoImageView.image = nil
        logoImageView.isHidden = true
        fallbackTitleLabel.text = nil
        fallbackTitleLabel.isHidden = false
        metaLabel.text = nil
        metaLabel.isHidden = true
        onPlay = nil
        onWatchlist = nil
    }

    func configure(with media: Media, isWatchlisted: Bool) {
        posterTask?.cancel()
        mediaID = media.id
        logoImageView.image = nil
        logoImageView.isHidden = true
        fallbackTitleLabel.text = media.displayName
        fallbackTitleLabel.isHidden = false
        setWatchlisted(isWatchlisted)
        setMeta(year: media.year, genre: nil)

        GenreProvider.shared.primaryGenreName(for: media.genreIds, type: media.mediaType) { [weak self] genre in
            guard let self = self, self.mediaID == media.id else { return }
            self.setMeta(year: media.year, genre: genre)
        }

        let fallbackURL = media.largePosterURL ?? media.fullBackdropURL
        loadPosterImage(from: fallbackURL, for: media)

        posterTask = Task { [weak self] in
            let artwork = await TMDBService.shared.fetchHeroArtwork(for: media.id, type: media.mediaType)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self = self, self.mediaID == media.id else { return }
                if let textlessPath = artwork.textlessPosterPath,
                   textlessPath != media.posterPath,
                   let textlessURL = TMDBImageURL.url(path: textlessPath, width: .wide) {
                    self.loadPosterImage(from: textlessURL, for: media)
                }
                if let logoPath = artwork.logoPath,
                   let logoURL = TMDBImageURL.url(path: logoPath, width: .poster) {
                    self.loadLogoImage(from: logoURL, for: media.id)
                }
            }
        }
    }

    private func loadLogoImage(from url: URL, for id: Int) {
        ImageLoader.load(url: url) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self, self.mediaID == id, let image else { return }
                self.logoImageView.image = image
                self.logoImageView.isHidden = false
                self.fallbackTitleLabel.isHidden = true
            }
        }
    }

    private func loadPosterImage(from url: URL?, for media: Media) {
        guard let url else {
            showArtworkPlaceholder(isUpcoming: media.ratingState.isUpcoming)
            return
        }
        ImageLoader.load(url: url) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self, self.mediaID == media.id else { return }
                guard let image = image else {
                    if self.imageView.image == nil {
                        self.showArtworkPlaceholder(isUpcoming: media.ratingState.isUpcoming)
                    }
                    return
                }
                self.imageView.contentMode = .scaleAspectFill
                self.imageView.image = image
            }
        }
    }

    func setWatchlisted(_ isWatchlisted: Bool) {
        var config = watchlistButton.configuration ?? .filled()
        config.image = UIImage(
            systemName: isWatchlisted ? "checkmark" : "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        config.attributedTitle = AttributedString(
            isWatchlisted ? "In Watchlist" : "Add to Watchlist",
            attributes: AttributeContainer([.font: UIFont.movter(size: 14, weight: .semibold)])
        )
        watchlistButton.configuration = config
        watchlistButton.accessibilityLabel = isWatchlisted ? "Remove from watchlist" : "Add to watchlist"
    }

    private func setMeta(year: String?, genre: String?) {
        let parts = [year, genre].compactMap { $0 }.filter { !$0.isEmpty }
        metaLabel.text = parts.joined(separator: " · ")
        metaLabel.isHidden = parts.isEmpty
    }

    private func showArtworkPlaceholder(isUpcoming: Bool) {
        imageView.contentMode = .center
        imageView.image = UIImage(
            systemName: isUpcoming ? "calendar" : "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        )
    }
}
