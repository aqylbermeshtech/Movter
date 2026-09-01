//
//  HeroCarouselView.swift
//  Movter
//
//  Created by Nurtore on 23.08.2026.
//

import UIKit

/// Full-bleed, paged carousel of landscape backdrop art with a title overlay and page
/// dots — the banner above the vertical-poster trending row. TMDB has no distinct
/// "horizontal poster" field; `backdrop_path` (16:9) is what feeds this.
final class HeroCarouselView: UIView {
    var onMovieSelected: ((Media) -> Void)?
    private var items: [Media] = []

    private static let horizontalInset: CGFloat = 16
    /// Backdrops are 16:9; this leaves a little extra for the title overlay to breathe.
    static let imageAspect: CGFloat = 0.56
    private static let pageControlHeight: CGFloat = 24
    private static let pageControlSpacing: CGFloat = 8

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

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .accent
        pc.pageIndicatorTintColor = .hairline
        pc.hidesForSinglePage = true
        pc.isUserInteractionEnabled = false
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

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
        addSubview(pageControl)
        collectionView.delegate = self
        collectionView.dataSource = self

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: Self.imageAspect,
                constant: -Self.horizontalInset * 2 * Self.imageAspect
            ),

            pageControl.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Self.pageControlSpacing),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: Self.pageControlHeight)
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
        pageControl.numberOfPages = items.count
        pageControl.currentPage = 0
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.collectionView.setContentOffset(.zero, animated: false)
            self.skeletonView.endLoading()
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
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onMovieSelected?(items[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        pageControl.currentPage = max(0, min(page, items.count - 1))
    }
}

/// One full-bleed backdrop with a bottom gradient and title, no card chrome — the
/// image itself is the whole cell, inset from the carousel's edges.
final class HeroCarouselCell: UICollectionViewCell {
    static let identifier = "HeroCarouselCell"

    private static let sideInset: CGFloat = 16

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.layer.cornerCurve = .continuous
        iv.backgroundColor = .surface
        iv.tintColor = .textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Bottom-anchored fade so the title stays legible over bright artwork.
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.75).cgColor]
        layer.locations = [0, 1]
        return layer
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.75)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageView.addSubview(titleLabel)
        imageView.addSubview(yearLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.sideInset),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.sideInset),

            yearLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 14),
            yearLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -14),
            yearLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -12),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: yearLabel.topAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        titleLabel.text = nil
        yearLabel.text = nil
    }

    func configure(with media: Media) {
        titleLabel.text = media.displayName
        yearLabel.text = media.year
        if let url = media.fullBackdropURL {
            ImageLoader.load(url: url) { [weak self] image in
                DispatchQueue.main.async {
                    guard let image = image else {
                        self?.showBackdropPlaceholder()
                        return
                    }
                    self?.imageView.contentMode = .scaleAspectFill
                    self?.imageView.image = image
                }
            }
        } else {
            showBackdropPlaceholder()
        }
    }

    private func showBackdropPlaceholder() {
        imageView.contentMode = .center
        imageView.image = UIImage(
            systemName: "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        )
    }
}
