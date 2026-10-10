//
//  MovieCell.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

final class MediaCell: UICollectionViewCell {
    static let identifier = "MediaCell"

    private var posterURL: URL?

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
        label.font = .cellTitle
        label.numberOfLines = 2
        label.textColor = .textPrimary
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .fineprint
        label.textColor = .textPrimary
        return label
    }()

    private let ratingBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .badge
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .microLabel
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var placeholderView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [placeholderIcon, placeholderLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isHidden = true
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        placeholderView.isHidden = true
        posterURL = nil
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
        
        contentView.addSubview(placeholderView)
        contentView.addSubview(ratingBadge)
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            placeholderView.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 8),
            placeholderView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -8),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 26),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 26),

            ratingBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            ratingBadge.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
    var posterAnchor: PosterTransitionAnchor {
        PosterTransitionAnchor(view: imageView, cornerRadius: imageView.layer.cornerRadius)
    }

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
        posterURL = media.fullPosterURL
        if let url = posterURL {
            ImageLoader.load(url: url) { [weak self] image in
                guard let self = self, self.posterURL == url else { return }
                guard let image = image else {
                    self.showPosterPlaceholder(isUpcoming: media.ratingState.isUpcoming)
                    return
                }
                self.placeholderView.isHidden = true
                self.imageView.image = image
            }
        } else {
            showPosterPlaceholder(isUpcoming: media.ratingState.isUpcoming)
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
        case let .upcoming(releaseDate):
            // No score, and none coming for a while — so say when instead of hiding.
            ratingBadgeLabel.text = RatingFormatter.upcomingBadgeText(releaseDate: releaseDate)
            ratingBadge.isHidden = false

        case .unrated:
            ratingBadge.isHidden = true
        }
    }

    private func showPosterPlaceholder(isUpcoming: Bool) {
        imageView.image = nil
        placeholderIcon.image = UIImage(
            systemName: isUpcoming ? "calendar" : "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        )
        placeholderLabel.text = isUpcoming ? "Coming soon" : nil
        placeholderLabel.isHidden = !isUpcoming
        placeholderView.isHidden = false
    }
}
