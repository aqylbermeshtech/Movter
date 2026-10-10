//
//  MediaDetailsViewController.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

final class MediaDetailsViewController: UIViewController {

    private let viewModel: MediaDetailsViewModel
    private let scrollView = UIScrollView()
    private let posterTransition = PosterTransitionController()
    private var isBarCollapsed = false
    private var keyboardOverlap: CGFloat = 0

    private let revealsTrailer: Bool
    private var didRevealTrailer = false

    init(viewModel: MediaDetailsViewModel, revealsTrailer: Bool = false) {
        self.viewModel = viewModel
        self.revealsTrailer = revealsTrailer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .surface
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var trailerButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .onAccent
        config.imagePadding = 6
        config.image = UIImage(
            systemName: "play.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        config.attributedTitle = AttributedString(
            "Trailer",
            attributes: AttributeContainer([.font: UIFont.capsuleButton])
        )
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 18)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(trailerTapped), for: .touchUpInside)
        button.isHidden = true
        button.accessibilityHint = "Plays the trailer"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var watchlistButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 18)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(watchlistTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var watchedButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(watchedTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .metadata
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionView: ExpandableTextLabel = {
        let view = ExpandableTextLabel()
        view.font = .body
        view.collapsedLineLimit = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let castCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 150)
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let castLabel: UILabel = {
        let label = UILabel()
        label.font = .sectionHeader
        label.text = "Cast & Crew"
        label.textColor = .textPrimary
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let castChevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        ))
        iv.tintColor = .textSecondary
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private lazy var castHeaderView: UIControl = {
        let control = UIControl()
        control.addTarget(self, action: #selector(showCastAndCrew), for: .touchUpInside)
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        control.accessibilityLabel = "Cast and crew"
        control.accessibilityHint = "Shows the full cast and crew list"
        control.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [castLabel, castChevronView, spacer])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false

        control.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: control.topAnchor),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor)
        ])
        return control
    }()

    private let similarLabel: UILabel = {
        let label = UILabel()
        label.font = .sectionHeader
        label.text = "More Like This"
        label.textColor = .textPrimary
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let similarCarouselView: SimilarCarouselView = {
        let view = SimilarCarouselView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let reviewLabel: UILabel = {
        let label = UILabel()
        label.font = .sectionHeader
        label.text = "Your Review"
        label.textColor = .textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let miniReviewView: MiniReviewView = {
        let view = MiniReviewView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let castPlaceholderTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .placeholderTitle
        label.textColor = .textPrimary
        return label
    }()

    private let castPlaceholderSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .caption
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var castPlaceholderView: UIView = {
        let container = UIView()
        container.backgroundColor = .surface
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.trackInterfaceStyle {
            $0.layer.borderColor = UIColor.textPrimary.withAlphaComponent(0.16).cgColor
        }
        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
        let symbol = UIImage(systemName: "person.2.slash", withConfiguration: config)
            ?? UIImage(systemName: "person.2.fill", withConfiguration: config)
        let iconView = UIImageView(image: symbol)
        iconView.tintColor = .textSecondary
        iconView.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [
            iconView, castPlaceholderTitleLabel, castPlaceholderSubtitleLabel
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.setCustomSpacing(14, after: iconView)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24)
        ])
        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas
        castCollectionView.delegate = self
        castCollectionView.dataSource = self
        castCollectionView.register(ActorsCell.self, forCellWithReuseIdentifier: ActorsCell.identifier)
        setupUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(connectivityChanged),
            name: NetworkMonitor.connectivityDidChangeNotification, object: nil
        )
        configure()
        bindViewModel()
        renderWatchedState()
        renderWatchlistState()
        viewModel.loadWatchedState()
        viewModel.loadWatchlistState()
        viewModel.fetchTrailer()
        viewModel.fetchCredits()
        viewModel.fetchSimilar()
        viewModel.fetchGenre()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: ThemeManager.themeDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func configure() {
        descriptionView.text = viewModel.overview
        descriptionView.isHidden = viewModel.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        renderMetadata()

        if let url = viewModel.largeImageURL {
            ImageLoader.load(url: url) { [weak self] image in
                self?.imageView.image = image
            }
        }
    }
    
    private func bindViewModel() {
        viewModel.onWatchedChange = { [weak self] in
            self?.renderWatchedState()
        }
        viewModel.onWatchlistChange = { [weak self] in
            self?.renderWatchlistState()
        }
        viewModel.onVideoUpdate = { [weak self] _ in
            guard let self = self else { return }
            self.trailerButton.isHidden = self.viewModel.trailerRequest == nil
            self.openTrailerIfRequested()
        }
        viewModel.onCreditsUpdate = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.castCollectionView.reloadData()
                self.renderCastState()
            }
        }
        viewModel.onSimilarUpdate = { [weak self] in
            DispatchQueue.main.async { self?.renderSimilar() }
        }
        viewModel.onGenreUpdate = { [weak self] in
            DispatchQueue.main.async { self?.renderMetadata() }
        }
        viewModel.onReviewUpdate = { [weak self] in
            guard let self = self else { return }
            guard !self.miniReviewView.isEditingOpinion else { return }
            self.miniReviewView.configure(with: self.viewModel.existingReview)
        }

        similarCarouselView.onSelect = { [weak self] media in
            guard let self = self else { return }
            let detailsVC = MediaDetailsViewController(viewModel: MediaDetailsViewModel(media: media))
            self.posterTransition.push(detailsVC, for: media, from: self)
        }

        descriptionView.onToggle = { [weak self] in
            self?.view.layoutIfNeeded()
        }

        miniReviewView.onSeeTicket = { [weak self] in
            self?.showTicket()
        }
        miniReviewView.onScoreChange = { [weak self] score in
            guard Review.scoreRange.contains(score) else { return }
            self?.viewModel.markWatchedIfNeeded()
        }
        miniReviewView.onSave = { [weak self] score, text in
            guard let self = self else { return }
            self.miniReviewView.setSaving(true)
            self.viewModel.saveReview(score: score, text: text) { result in
                self.miniReviewView.setSaving(false)
                switch result {
                case .success:
                    self.viewModel.markWatchedIfNeeded()
                    self.miniReviewView.showSaved()
                case let .failure(error):
                    self.miniReviewView.showError(error.localizedDescription)
                }
            }
        }
    }

    @objc private func themeDidChange() {
        renderMetadata()
        renderWatchedState()
        renderWatchlistState()
    }

    @objc private func watchedTapped() {
        viewModel.toggleWatched()
    }

    @objc private func watchlistTapped() {
        viewModel.toggleWatchlist()
    }

    private func renderWatchlistState() {
        let isInWatchlist = viewModel.isInWatchlist
        watchlistButton.configuration?.baseBackgroundColor = isInWatchlist ? .accent : .surface
        watchlistButton.configuration?.baseForegroundColor = isInWatchlist ? .onAccent : .textPrimary
        watchlistButton.configuration?.image = UIImage(
            systemName: viewModel.watchlistButtonSymbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        watchlistButton.configuration?.attributedTitle = AttributedString(
            viewModel.watchlistButtonTitle,
            attributes: AttributeContainer([.font: UIFont.capsuleButton])
        )
        watchlistButton.accessibilityLabel = isInWatchlist
            ? "In your watchlist. Double tap to remove." : "Add to watchlist"
    }

    private func renderWatchedState() {
        let isWatched = viewModel.isWatched
        watchedButton.configuration?.baseBackgroundColor = isWatched ? .surface : .accent
        watchedButton.configuration?.baseForegroundColor = isWatched ? .textPrimary : .onAccent
        watchedButton.configuration?.image = UIImage(
            systemName: viewModel.watchedButtonSymbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        watchedButton.configuration?.attributedTitle = AttributedString(
            viewModel.watchedButtonTitle,
            attributes: AttributeContainer([.font: UIFont.button])
        )
        watchedButton.accessibilityLabel = isWatched
            ? "Watched. Double tap to unmark." : "Mark as watched"
    }

    @objc private func connectivityChanged() {
        viewModel.connectivityDidChange()
        renderCastState()
    }

    private func renderCastState() {
        let showPlaceholder = viewModel.hasLoadedActors && viewModel.actors.isEmpty
        castPlaceholderTitleLabel.text = viewModel.castPlaceholderTitle
        castPlaceholderSubtitleLabel.text = viewModel.castPlaceholderSubtitle
        castPlaceholderView.isHidden = !showPlaceholder
        castCollectionView.isHidden = showPlaceholder

        // Nothing to push to until the credits are in, so the heading stays a heading.
        castHeaderView.isEnabled = viewModel.hasCredits
        castChevronView.isHidden = !viewModel.hasCredits
        castHeaderView.accessibilityTraits = viewModel.hasCredits ? .button : .header
    }

    @objc private func showCastAndCrew() {
        guard viewModel.hasCredits else { return }
        let castCrewVC = CastCrewViewController(viewModel: viewModel.makeCastCrewViewModel())
        navigationController?.pushViewController(castCrewVC, animated: true)
    }
    
    private func renderSimilar() {
        similarCarouselView.update(with: viewModel.similar)
        similarLabel.isHidden = !viewModel.hasSimilar
        similarCarouselView.isHidden = !viewModel.hasSimilar
    }

    private func renderMetadata() {
        metadataLabel.attributedText = RatingFormatter.metadataLine(
            state: viewModel.ratingState,
            year: viewModel.year,
            genre: viewModel.genreName,
            font: metadataLabel.font
        )
    }
    
    private func showTicket() {
        guard let review = viewModel.existingReview else { return }
        let ticketVC = TicketViewController(review: review)
        present(UINavigationController(rootViewController: ticketVC), animated: true)
    }

    @objc private func trailerTapped() {
        guard let request = viewModel.trailerRequest else { return }
        let trailerVC = TrailerViewController(filmTitle: viewModel.title, request: request)
        navigationController?.pushViewController(trailerVC, animated: true)
    }

    private func openTrailerIfRequested() {
        guard revealsTrailer, !didRevealTrailer, viewModel.trailerRequest != nil else { return }
        didRevealTrailer = true
        trailerTapped()
    }

    private func setupUI() {
        metadataLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let actionRow = UIStackView(arrangedSubviews: [watchlistButton, trailerButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 10
        actionRow.alignment = .fill
        actionRow.distribution = .fill

        let splitRatio = trailerButton.widthAnchor.constraint(
            equalTo: watchlistButton.widthAnchor, multiplier: 3.0 / 7.0
        )
        splitRatio.priority = UILayoutPriority(999)
        splitRatio.isActive = true
        trailerButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [actionRow, metadataLabel])
        headerRow.axis = .vertical
        headerRow.spacing = 12

        let stack = UIStackView(arrangedSubviews: [
            headerRow,
            descriptionView,
            reviewLabel,
            miniReviewView,
            watchedButton,
            castHeaderView,
            castCollectionView,
            castPlaceholderView,
            similarLabel,
            similarCarouselView
        ])

        stack.axis = .vertical
        stack.spacing = 20
        stack.setCustomSpacing(10, after: reviewLabel)
        stack.setCustomSpacing(10, after: castHeaderView)
        stack.setCustomSpacing(12, after: miniReviewView)
        stack.setCustomSpacing(10, after: similarLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.keyboardDismissMode = .interactive

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardOnTap))
        dismissTap.cancelsTouchesInView = false
        dismissTap.delegate = self
        scrollView.addGestureRecognizer(dismissTap)
        scrollView.addSubview(imageView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            // TMDB posters are 2:3, so this shows the artwork uncropped.
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0 / 2.0),

            stack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            castCollectionView.heightAnchor.constraint(equalToConstant: 160),
            similarCarouselView.heightAnchor.constraint(equalToConstant: SimilarCarouselView.preferredHeight),
            castPlaceholderView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollInsets()
    }

    private func updateScrollInsets() {
        let bottom = max(view.safeAreaInsets.bottom + MainTabBarController.contentClearance, keyboardOverlap)
        guard scrollView.contentInset.bottom != bottom else { return }
        scrollView.contentInset.bottom = bottom
        scrollView.verticalScrollIndicatorInsets.bottom = bottom
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        keyboardOverlap = max(0, view.bounds.maxY - view.convert(frame, from: nil).minY)
        updateScrollInsets()

        if miniReviewView.isEditingOpinion {
            let rect = scrollView.convert(miniReviewView.bounds, from: miniReviewView)
            scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -12), animated: true)
        }
    }

    @objc private func dismissKeyboardOnTap() {
        view.endEditing(true)
    }

    @objc private func keyboardWillHide() {
        keyboardOverlap = 0
        updateScrollInsets()
    }

    // MARK: - Navigation bar

    private static func transparentBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        return appearance
    }

    private static func opaqueBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        return appearance
    }

    private func applyBarAppearance(collapsed: Bool) {
        guard let bar = navigationController?.navigationBar else { return }
        let appearance = collapsed ? Self.opaqueBarAppearance() : Self.transparentBarAppearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = .textPrimary
        navigationItem.title = collapsed ? viewModel.title : nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBarAppearance(collapsed: isBarCollapsed)
        viewModel.loadReview()
        viewModel.loadWatchedState()
        viewModel.loadWatchlistState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let opaque = Self.opaqueBarAppearance()
        navigationController?.navigationBar.standardAppearance = opaque
        navigationController?.navigationBar.scrollEdgeAppearance = opaque
        navigationController?.navigationBar.compactAppearance = opaque
    }
}

extension MediaDetailsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }

        let barBottom = view.safeAreaInsets.top + (navigationController?.navigationBar.bounds.height ?? 44)
        let collapsed = scrollView.contentOffset.y > imageView.bounds.height - barBottom
        guard collapsed != isBarCollapsed else { return }

        isBarCollapsed = collapsed
        UIView.animate(withDuration: 0.2) { self.applyBarAppearance(collapsed: collapsed) }
    }
}

extension MediaDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.actors.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActorsCell.identifier, for: indexPath) as? ActorsCell else {
            return UICollectionViewCell()
        }
        let actor = viewModel.actors[indexPath.item]
        cell.configure(with: actor)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard viewModel.actors.indices.contains(indexPath.item) else { return }
        let actor = viewModel.actors[indexPath.item]
        let actorVM = ActorViewModel(actorId: actor.id, name: actor.name)
        let actorVC = ActorViewController(viewModel: actorVM)
        navigationController?.pushViewController(actorVC, animated: true)
    }
}


// MARK: - Tap-to-dismiss

extension MediaDetailsViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touched = touch.view else { return true }
        return !touched.isDescendant(of: miniReviewView)
    }
}


// MARK: - Poster transition

extension MediaDetailsViewController: PosterTransitionSource {
    func transitionPoster(forMediaID id: Int) -> PosterTransitionAnchor? {
        similarCarouselView.transitionPoster(forMediaID: id)
    }
}

extension MediaDetailsViewController: PosterTransitionDestination {
    var transitionPoster: UIImageView { imageView }
}
