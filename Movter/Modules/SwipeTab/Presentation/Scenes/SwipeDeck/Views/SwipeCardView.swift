//
//  SwipeCardView.swift
//  Movter
//
//  Created by Nurtore on 24.08.2026.
//

import UIKit

final class SwipeCardView: UIView {

    nonisolated enum PanReleaseDecision: Equatable {
        case tap
        case commit(SwipeDirection)
        case springBack
    }

    let media: Media
    var onSwiped: ((SwipeDirection) -> Void)?
    var onTapped: ((Media) -> Void)?
    var onDragProgress: ((CGFloat) -> Void)?
    var onThresholdHaptic: (() -> Void)?

    nonisolated static let rotationDivisor: CGFloat = 320
    nonisolated static let maxRotation: CGFloat = .pi / 8
    nonisolated static let commitDistanceFraction: CGFloat = 0.32
    nonisolated static let commitVelocity: CGFloat = 700
    nonisolated static let tapMovementTolerance: CGFloat = 6
    nonisolated static let velocityProjectionTime: CGFloat = 0.12
    nonisolated static let opposingMomentumLimit: CGFloat = -15_000
    nonisolated static let hapticResetThreshold: CGFloat = 0.85

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.layer.cornerCurve = .continuous
        iv.backgroundColor = .surface
        iv.tintColor = .textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.92).cgColor
        ]
        layer.locations = [0.0, 0.55, 1.0]
        return layer
    }()

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let fallbackTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .cardTitle
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ratingPill = MetadataPillView()
    private let genrePill = MetadataPillView()
    private let yearPill = MetadataPillView()

    private lazy var metadataStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ratingPill, genrePill, yearPill])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let likeDestinationView = SwipeCardView.makeDestinationOverlay(
        systemImage: "bookmark.fill", caption: "Watchlist", tint: .accent
    )
    private let passDestinationView = SwipeCardView.makeDestinationOverlay(
        systemImage: "clock.arrow.circlepath", caption: "Maybe Later", tint: .destructive
    )

    private var panStartCenter: CGPoint?
    private(set) var hasCommitted = false
    private(set) var lastCommittedDirection: SwipeDirection?
    private(set) var didTriggerThresholdHaptic = false
    private(set) var posterCrossDissolveCount = 0
    private lazy var impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let loadRemoteArtwork: Bool
    private let genreProvider: GenreProviding
    private var artworkTask: Task<Void, Never>?

    var gradientLocations: [NSNumber]? { gradientLayer.locations }
    var ratingPillText: String? { ratingPill.isHidden ? nil : ratingPill.label.text }
    var genrePillText: String? { genrePill.isHidden ? nil : genrePill.label.text }
    var yearPillText: String? { yearPill.isHidden ? nil : yearPill.label.text }
    var isMetadataStackHidden: Bool { metadataStackView.isHidden }

    init(
        media: Media,
        loadRemoteArtwork: Bool = true,
        genreProvider: GenreProviding = GenreProvider.shared
    ) {
        self.media = media
        self.loadRemoteArtwork = loadRemoteArtwork
        self.genreProvider = genreProvider
        super.init(frame: .zero)
        setupUI()
        configure()
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    deinit {
        artworkTask?.cancel()
    }

    required init?(coder: NSCoder) { fatalError() }

    var posterAnchor: PosterTransitionAnchor {
        PosterTransitionAnchor(view: imageView, cornerRadius: imageView.layer.cornerRadius)
    }

    private func setupUI() {
        backgroundColor = .surface
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageView.addSubview(logoImageView)
        imageView.addSubview(fallbackTitleLabel)
        imageView.addSubview(metadataStackView)
        addSubview(likeDestinationView)
        addSubview(passDestinationView)

        ratingPill.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingPill.label.setContentCompressionResistancePriority(.required, for: .horizontal)
        yearPill.setContentCompressionResistancePriority(.required, for: .horizontal)
        yearPill.label.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            metadataStackView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            metadataStackView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -20),
            metadataStackView.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 20),
            metadataStackView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -20),

            logoImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: metadataStackView.topAnchor, constant: -10),
            logoImageView.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 24),
            logoImageView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -24),
            logoImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 240),
            logoImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 76),

            fallbackTitleLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            fallbackTitleLabel.bottomAnchor.constraint(equalTo: metadataStackView.topAnchor, constant: -10),
            fallbackTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 20),
            fallbackTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -20),

            likeDestinationView.topAnchor.constraint(equalTo: topAnchor),
            likeDestinationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            likeDestinationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            likeDestinationView.bottomAnchor.constraint(equalTo: bottomAnchor),

            passDestinationView.topAnchor.constraint(equalTo: topAnchor),
            passDestinationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            passDestinationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            passDestinationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configure() {
        fallbackTitleLabel.text = media.displayName
        configureMetadataPills()

        guard loadRemoteArtwork else {
            if media.posterPath == nil {
                showPosterPlaceholder()
            }
            return
        }
        loadPoster(from: media.largePosterURL ?? media.fullPosterURL)

        artworkTask = Task { [weak self, media] in
            let artwork = await TMDBService.shared.fetchHeroArtwork(for: media.id, type: media.mediaType)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self = self else { return }
                if let textlessPath = artwork.textlessPosterPath,
                   textlessPath != media.posterPath,
                   let textlessURL = TMDBImageURL.url(path: textlessPath, width: .wide) {
                    self.loadPoster(from: textlessURL, isUpgrade: true)
                }
                if let logoPath = artwork.logoPath,
                   let logoURL = TMDBImageURL.url(path: logoPath, width: .poster) {
                    self.loadLogo(from: logoURL)
                }
            }
        }
    }

    private func configureMetadataPills() {
        if WatchlistItem(from: media).isUnreleased || media.ratingState.isUpcoming {
            ratingPill.configure(text: "Upcoming")
        } else {
            switch media.ratingState {
            case .rated(let score, _), .provisional(let score, _):
                ratingPill.configure(text: String(format: "★ %.1f", score))
            case .unrated, .upcoming:
                ratingPill.configure(text: nil)
            }
        }

        genrePill.configure(text: nil)
        if let year = media.year, !year.isEmpty {
            yearPill.configure(text: year)
        } else {
            yearPill.configure(text: nil)
        }
        updateMetadataStackVisibility()

        if loadRemoteArtwork || (genreProvider !== GenreProvider.shared) {
            genreProvider.primaryGenreName(for: media.genreIds, type: media.mediaType) { [weak self] genre in
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        self?.applyGenreName(genre)
                    }
                } else {
                    DispatchQueue.main.async {
                        MainActor.assumeIsolated {
                            self?.applyGenreName(genre)
                        }
                    }
                }
            }
        }
    }

    private func applyGenreName(_ genre: String?) {
        let trimmed = genre?.trimmingCharacters(in: .whitespacesAndNewlines)
        genrePill.configure(text: (trimmed?.isEmpty == false) ? trimmed : nil)
        updateMetadataStackVisibility()
    }

    private func updateMetadataStackVisibility() {
        metadataStackView.isHidden = ratingPill.isHidden && genrePill.isHidden && yearPill.isHidden
    }

    func applyPosterImage(_ image: UIImage, isUpgrade: Bool) {
        if isUpgrade && imageView.image != nil {
            posterCrossDissolveCount += 1
            UIView.transition(
                with: imageView,
                duration: 0.25,
                options: [.transitionCrossDissolve, .allowUserInteraction],
                animations: {
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.image = image
                }
            )
        } else {
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
        }
    }

    private func loadPoster(from url: URL?, isUpgrade: Bool = false) {
        guard let url else {
            if !isUpgrade {
                showPosterPlaceholder()
            }
            return
        }
        ImageLoader.load(url: url) { [weak self] image in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self = self else { return }
                    guard let image = image else {
                        if self.imageView.image == nil {
                            self.showPosterPlaceholder()
                        }
                        return
                    }
                    self.applyPosterImage(image, isUpgrade: isUpgrade)
                }
            }
        }
    }

    private func loadLogo(from url: URL) {
        ImageLoader.load(url: url) { [weak self] image in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self = self, let image else { return }
                    self.logoImageView.image = image
                    self.logoImageView.isHidden = false
                    self.fallbackTitleLabel.isHidden = true
                }
            }
        }
    }

    private func showPosterPlaceholder() {
        imageView.contentMode = .center
        imageView.image = UIImage(
            systemName: "film",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
    }

    // MARK: - Gesture

    nonisolated static func dragProgress(forTranslationX translationX: CGFloat, cardWidth: CGFloat) -> CGFloat {
        guard cardWidth > 0, cardWidth.isFinite, translationX.isFinite else { return 0 }
        let threshold = cardWidth * commitDistanceFraction
        guard threshold > 0, threshold.isFinite else { return 0 }
        return min(abs(translationX) / threshold, 1.0)
    }

    nonisolated static func evaluatePanRelease(
        translation: CGPoint,
        velocity: CGPoint,
        cardWidth: CGFloat,
        isCancelled: Bool = false
    ) -> PanReleaseDecision {
        guard !isCancelled else { return .springBack }
        guard translation.x.isFinite, translation.y.isFinite,
              velocity.x.isFinite, velocity.y.isFinite else {
            return .springBack
        }
        if abs(translation.x) < tapMovementTolerance && abs(translation.y) < tapMovementTolerance {
            return .tap
        }
        guard cardWidth > 0, cardWidth.isFinite else { return .springBack }

        let projectedX = translation.x + velocity.x * velocityProjectionTime
        let momentum = translation.x * velocity.x
        let distanceCommitted = abs(translation.x) > cardWidth * commitDistanceFraction
            && momentum >= opposingMomentumLimit
        let velocityCommitted = abs(velocity.x) > commitVelocity && momentum > 0

        if distanceCommitted || velocityCommitted {
            return .commit(projectedX > 0 ? .like : .pass)
        }
        return .springBack
    }

    @objc private func handleTap() {
        onTapped?(media)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let referenceView = superview ?? self
        handlePanUpdate(
            translation: gesture.translation(in: referenceView),
            velocity: gesture.velocity(in: referenceView),
            state: gesture.state
        )
    }

    func handlePanUpdate(
        translation: CGPoint,
        velocity: CGPoint = .zero,
        state: UIGestureRecognizer.State
    ) {
        guard !hasCommitted else { return }

        switch state {
        case .began:
            panStartCenter = center
            didTriggerThresholdHaptic = false
            impactGenerator.prepare()

        case .changed:
            guard translation.x.isFinite, translation.y.isFinite else { return }
            let startCenter = panStartCenter ?? center
            if panStartCenter == nil {
                panStartCenter = startCenter
            }

            center = CGPoint(x: startCenter.x + translation.x, y: startCenter.y + translation.y)
            let rotation = (translation.x / Self.rotationDivisor).clamped(to: -Self.maxRotation...Self.maxRotation)
            transform = CGAffineTransform(rotationAngle: rotation)

            let progress = Self.dragProgress(forTranslationX: translation.x, cardWidth: bounds.width)
            likeDestinationView.alpha = translation.x > 0 ? progress : 0
            passDestinationView.alpha = translation.x < 0 ? progress : 0
            onDragProgress?(progress)

            if bounds.width > 0, bounds.width.isFinite {
                if progress >= 1.0, !didTriggerThresholdHaptic {
                    didTriggerThresholdHaptic = true
                    triggerThresholdHaptic()
                } else if progress < Self.hapticResetThreshold, didTriggerThresholdHaptic {
                    didTriggerThresholdHaptic = false
                }
            }

        case .ended:
            didTriggerThresholdHaptic = false
            let decision = Self.evaluatePanRelease(
                translation: translation,
                velocity: velocity,
                cardWidth: bounds.width,
                isCancelled: false
            )
            switch decision {
            case .tap:
                if let startCenter = panStartCenter {
                    center = startCenter
                }
                panStartCenter = nil
                transform = .identity
                likeDestinationView.alpha = 0
                passDestinationView.alpha = 0
                onDragProgress?(0)
                onTapped?(media)

            case .commit(let direction):
                commitSwipe(direction: direction, exitVelocity: velocity)

            case .springBack:
                springBack()
            }

        case .cancelled, .failed:
            didTriggerThresholdHaptic = false
            springBack()

        default:
            break
        }
    }

    private func triggerThresholdHaptic() {
        impactGenerator.impactOccurred()
        onThresholdHaptic?()
    }

    func performSwipe(direction: SwipeDirection) {
        commitSwipe(direction: direction, exitVelocity: .zero)
    }

    private func commitSwipe(direction: SwipeDirection, exitVelocity: CGPoint) {
        guard !hasCommitted else { return }
        hasCommitted = true
        lastCommittedDirection = direction
        didTriggerThresholdHaptic = false
        panStartCenter = nil
        isUserInteractionEnabled = false

        let travel = superview?.bounds.width ?? bounds.width
        let destinationX = center.x + (direction == .like ? travel : -travel)
        let rotation = direction == .like ? Self.maxRotation : -Self.maxRotation
        let safeVelocityY = exitVelocity.y.isFinite ? exitVelocity.y : 0

        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn], animations: {
            self.center = CGPoint(x: destinationX, y: self.center.y + safeVelocityY * 0.15)
            self.transform = CGAffineTransform(rotationAngle: rotation)
            self.likeDestinationView.alpha = direction == .like ? 1 : 0
            self.passDestinationView.alpha = direction == .pass ? 1 : 0
            self.onDragProgress?(1)
        }, completion: { [weak self] _ in
            self?.onSwiped?(direction)
        })
    }

    func springBack() {
        guard !hasCommitted else { return }
        let targetCenter = panStartCenter ?? center
        panStartCenter = nil
        didTriggerThresholdHaptic = false

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction],
            animations: {
                self.center = targetCenter
                self.transform = .identity
                self.likeDestinationView.alpha = 0
                self.passDestinationView.alpha = 0
                self.onDragProgress?(0)
            }
        )
    }

    private static func makeDestinationOverlay(systemImage: String, caption: String, tint: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = .canvas
        container.layer.cornerRadius = 20
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true
        container.alpha = 0
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .semibold)
        ))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = caption
        label.font = .movter(size: 18, weight: .bold)
        label.textColor = tint

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}

private final class MetadataPillView: UIView {
    let label: UILabel = {
        let label = UILabel()
        label.font = .badge
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.55)
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        clipsToBounds = true
        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func configure(text: String?) {
        if let text, !text.isEmpty {
            label.text = text
            isHidden = false
        } else {
            label.text = nil
            isHidden = true
        }
    }
}
