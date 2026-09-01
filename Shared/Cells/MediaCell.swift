//
//  MovieCell.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

final class MediaCell: UICollectionViewCell {
    static let identifier = "MediaCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .surface
        iv.tintColor = .textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 2
        label.textColor = .textPrimary
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .textPrimary
        return label
    }()

    /// The score over the artwork, for carousels with no caption line to carry it.
    /// White on a scrim rather than the accent: the accent inverts with the appearance,
    /// and half of its range is invisible against a dark chip.
    private let ratingBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var ratingBadge: UIView = {
        let badge = UIView()
        badge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        badge.layer.cornerRadius = 9
        badge.layer.cornerCurve = .continuous
        badge.isHidden = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(ratingBadgeLabel)
        NSLayoutConstraint.activate([
            ratingBadgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 3),
            ratingBadgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -3),
            ratingBadgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 8),
            ratingBadgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -8)
        ])
        return badge
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        titleLabel.text = nil
        ratingLabel.attributedText = nil
        titleLabel.isHidden = false
        ratingLabel.isHidden = false
        ratingBadge.isHidden = true
        ratingBadgeLabel.attributedText = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, ratingLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        stack.distribution = .fill

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.5)
        ])

        contentView.addSubview(ratingBadge)
        NSLayoutConstraint.activate([
            ratingBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            ratingBadge.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// The artwork alone, handed to the details transition to fly out of. The radius is
    /// read off the layer so the flight can't drift out of step with the cell's own
    /// rounding if that changes.
    var posterAnchor: PosterTransitionAnchor {
        PosterTransitionAnchor(view: imageView, cornerRadius: imageView.layer.cornerRadius)
    }

    /// - Parameter showsCaption: false leaves just the poster, for the carousel.
    ///   Hidden arranged subviews drop out of the stack, so the cell's height becomes
    ///   the poster's alone.
    /// - Parameter showsRatingBadge: puts the score on the artwork instead. Only for a
    ///   title that actually has one — an "Announced" chip over a poster is noise, so
    ///   unrated and unreleased titles show nothing rather than a badge apologising.
    func configure(with media: Media, showsCaption: Bool = true, showsRatingBadge: Bool = false) {
        titleLabel.isHidden = !showsCaption
        ratingLabel.isHidden = !showsCaption
        configureRatingBadge(with: media, visible: showsRatingBadge)
        titleLabel.text = media.displayName
        ratingLabel.attributedText = RatingFormatter.attributedRating(
            media.ratingState,
            font: ratingLabel.font,
            textColor: .textPrimary,
            compact: true
        )
        if let url = media.fullPosterURL {
            ImageLoader.load(url: url) { [weak self] image in
                DispatchQueue.main.async {
                    guard let image = image else {
                        self?.showPosterPlaceholder()
                        return
                    }
                    self?.imageView.contentMode = .scaleAspectFill
                    self?.imageView.image = image
                }
            }
        } else {
            showPosterPlaceholder()
        }
    }

    private func configureRatingBadge(with media: Media, visible: Bool) {
        guard visible else {
            ratingBadge.isHidden = true
            return
        }
        switch media.ratingState {
        case .rated, .provisional:
            ratingBadgeLabel.attributedText = RatingFormatter.attributedRating(
                media.ratingState,
                font: ratingBadgeLabel.font,
                textColor: .white,
                starColor: .white,
                compact: true
            )
            ratingBadge.isHidden = false
        case .unrated, .upcoming:
            ratingBadge.isHidden = true
        }
    }

    /// Plenty of TMDB credits — talk-show appearances especially — ship without artwork.
    private func showPosterPlaceholder() {
        imageView.contentMode = .center
        imageView.image = UIImage(
            systemName: "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        )
    }
}
