//
//  SearchOverlayViewController.swift
//  Movter
//
//  Created by Nurtore on 27.08.2026.
//

import UIKit

/// The list's sections, ordered as they appear. `nonisolated` because the project
/// defaults types to `@MainActor`, and the diffable data source needs a `Sendable`
/// (non-isolated) `Hashable` conformance for its identifier types.
private nonisolated enum Section: Hashable {
    /// The single "Search for …" row shown while typing.
    case query
    /// Recents as wrapping chips — the idle state.
    case chips
    /// Recents as plain rows — filtered to the current query while typing.
    case recentRows
    case trending
    /// Placeholder rows while the trending request is in flight.
    case skeleton
}

private nonisolated enum Item: Hashable {
    case query(String)
    /// A recent term. Which section it lands in — `chips` or `recentRows` — decides how
    /// it's drawn; the two never coexist in one snapshot.
    case term(String)
    case trending(rank: Int, title: String)
    case skeleton(Int)
}

/// The search entry surface. Brought up full-screen — over everything, the floating tab
/// bar included — when the Search tab's action button is tapped, so nothing of the
/// underlying chrome shows through and there's no awkward layering with the glass bar.
///
/// It doesn't run the search itself: picking a recent or trending term, or typing a
/// query and hitting Search, hands the term back through `onSubmit` and dismisses. The
/// presenter pushes the results onto the Search tab, where they land in the normal
/// navigation stack with the tab bar back in place.
final class SearchOverlayViewController: UIViewController {

    /// Called with the chosen query just before the screen dismisses.
    var onSubmit: ((String) -> Void)?

    /// A typed query needs at least this many characters before it'll run — mirrors the
    /// guard the results screen applies.
    private static let minQueryLength = 2

    private static let sideInset: CGFloat = 16

    // MARK: - Header

    private let searchField: UISearchTextField = {
        let field = UISearchTextField()
        field.placeholder = "Search films"
        field.returnKeyType = .search
        field.enablesReturnKeyAutomatically = false
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.backgroundColor = .surface
        field.textColor = .textPrimary
        field.tintColor = .accent
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let headerSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .hairline
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - List

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.delegate = self
        cv.register(QueryRowCell.self, forCellWithReuseIdentifier: QueryRowCell.id)
        cv.register(TermRowCell.self, forCellWithReuseIdentifier: TermRowCell.id)
        cv.register(TrendingRowCell.self, forCellWithReuseIdentifier: TrendingRowCell.id)
        cv.register(SkeletonRowCell.self, forCellWithReuseIdentifier: SkeletonRowCell.id)
        cv.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.id)
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.id
        )
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Search for films by title"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - State

    private var recents: [String] = RecentSearchesStore.all()
    private var trending: [String] = []
    private var isLoadingTrending = true
    private var didAnimateIn = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .canvas

        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [searchField, cancelButton])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(headerSeparator)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.sideInset),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.sideInset),
            searchField.heightAnchor.constraint(equalToConstant: 44),

            headerSeparator.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            collectionView.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])

        configureDataSource()
        applySnapshot(animated: false)
        fetchTrending()

        // The field is already in place; only the list slides up under it.
        collectionView.alpha = 0
        collectionView.transform = CGAffineTransform(translationX: 0, y: 14)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()

        guard !didAnimateIn else { return }
        didAnimateIn = true
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.collectionView.alpha = 1
            self.collectionView.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func textChanged() {
        applySnapshot(animated: true)
    }

    @objc private func cancelTapped() {
        searchField.resignFirstResponder()
        dismiss(animated: true)
    }

    @objc private func keyboardWillChangeFrame(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, collectionView.frame.maxY - converted.minY)
        collectionView.contentInset.bottom = overlap
        collectionView.verticalScrollIndicatorInsets.bottom = overlap
    }

    // MARK: - Data

    private func fetchTrending() {
        NetworkService.shared.fetchTrendingContent(type: .movies) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingTrending = false
            guard case let .media(items) = result else { self.applySnapshot(animated: true); return }
            // Titles only — this list feeds queries, not a poster grid. De-duped because
            // a franchise can chart several times on the same day.
            self.trending = items
                .compactMap { $0.title ?? $0.name }
                .reduce(into: [String]()) { unique, title in
                    if !unique.contains(title) { unique.append(title) }
                }
            self.applySnapshot(animated: true)
        }
    }

    private func submit(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minQueryLength else { return }

        RecentSearchesStore.add(trimmed)
        let handler = onSubmit
        searchField.resignFirstResponder()
        dismiss(animated: true) { handler?(trimmed) }
    }

    private func removeRecent(_ term: String) {
        RecentSearchesStore.remove(term)
        recents = RecentSearchesStore.all()
        applySnapshot(animated: true)
    }

    private func clearRecents() {
        RecentSearchesStore.clear()
        recents = []
        applySnapshot(animated: true)
    }

    // MARK: - Snapshot

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        let typed = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if typed.isEmpty {
            if !recents.isEmpty {
                snapshot.appendSections([.chips])
                snapshot.appendItems(recents.map { .term($0) }, toSection: .chips)
            }
            if isLoadingTrending {
                snapshot.appendSections([.skeleton])
                snapshot.appendItems((0..<6).map { .skeleton($0) }, toSection: .skeleton)
            } else if !trending.isEmpty {
                snapshot.appendSections([.trending])
                snapshot.appendItems(
                    trending.prefix(10).enumerated().map { .trending(rank: $0.offset + 1, title: $0.element) },
                    toSection: .trending
                )
            }
        } else {
            if typed.count >= Self.minQueryLength {
                snapshot.appendSections([.query])
                snapshot.appendItems([.query(typed)], toSection: .query)
            }
            let matches = recents.filter { $0.range(of: typed, options: .caseInsensitive) != nil }
            if !matches.isEmpty {
                snapshot.appendSections([.recentRows])
                snapshot.appendItems(matches.map { .term($0) }, toSection: .recentRows)
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animated)
        emptyLabel.isHidden = !snapshot.sectionIdentifiers.isEmpty || isLoadingTrending
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, item in
            switch item {
            case let .query(text):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QueryRowCell.id, for: indexPath) as! QueryRowCell
                cell.configure(query: text)
                return cell

            case let .term(term):
                if self?.dataSource.sectionIdentifier(for: indexPath.section) == .chips {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChipCell.id, for: indexPath) as! ChipCell
                    cell.configure(term)
                    cell.onDelete = { [weak self] in self?.removeRecent(term) }
                    return cell
                }
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TermRowCell.id, for: indexPath) as! TermRowCell
                cell.configure(term)
                return cell

            case let .trending(rank, title):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendingRowCell.id, for: indexPath) as! TrendingRowCell
                cell.configure(rank: rank, title: title)
                return cell

            case let .skeleton(index):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SkeletonRowCell.id, for: indexPath) as! SkeletonRowCell
                cell.configure(index: index)
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: SectionHeaderView.id, for: indexPath
            ) as! SectionHeaderView

            switch self?.dataSource.sectionIdentifier(for: indexPath.section) {
            case .chips, .recentRows:
                view.configure(title: "Recent", actionTitle: "Clear") { [weak self] in self?.clearRecents() }
            case .trending, .skeleton:
                view.configure(title: "Trending", actionTitle: nil, action: nil)
            default:
                view.configure(title: nil, actionTitle: nil, action: nil)
            }
            return view
        }
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, environment in
            guard let self = self else { return nil }
            switch self.dataSource?.sectionIdentifier(for: index) {
            case .chips:
                return self.chipsSection(environment)
            case .query:
                return self.rowsSection(rowHeight: 58, hasHeader: false)
            case .recentRows:
                return self.rowsSection(rowHeight: 52, hasHeader: true)
            case .trending:
                return self.rowsSection(rowHeight: 52, hasHeader: true)
            case .skeleton:
                return self.rowsSection(rowHeight: 44, hasHeader: true)
            case .none:
                // Not reachable for a live section index; a compositional layout
                // provider isn't allowed to return nil, so hand back an empty section.
                return self.rowsSection(rowHeight: 0, hasHeader: false)
            }
        }
    }

    private func rowsSection(rowHeight: CGFloat, hasHeader: Bool) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .absolute(rowHeight)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(rowHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: Self.sideInset, bottom: 0, trailing: Self.sideInset)
        if hasHeader { section.boundarySupplementaryItems = [Self.headerItem()] }
        return section
    }

    private func chipsSection(_ environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let available = environment.container.effectiveContentSize.width - Self.sideInset * 2
        let (frames, totalHeight) = Self.chipFrames(for: recents, availableWidth: available)

        let group = NSCollectionLayoutGroup.custom(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(max(totalHeight, 1)))
        ) { _ in frames }

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 4, leading: Self.sideInset, bottom: 20, trailing: Self.sideInset)
        section.boundarySupplementaryItems = [Self.headerItem()]
        return section
    }

    private static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    /// Wraps the recent chips into lines that fit `availableWidth`, returning each
    /// chip's frame (in the group's own coordinate space) and the total stack height.
    /// Pure and deterministic — the compositional layout calls it once for the group
    /// height and again for the item frames.
    private static func chipFrames(
        for terms: [String], availableWidth: CGFloat
    ) -> (frames: [NSCollectionLayoutGroupCustomItem], height: CGFloat) {
        let chipHeight: CGFloat = 34
        let lineSpacing: CGFloat = 10
        let interItemSpacing: CGFloat = 8

        var frames: [NSCollectionLayoutGroupCustomItem] = []
        var x: CGFloat = 0
        var y: CGFloat = 0

        for term in terms {
            let width = min(ChipCell.width(for: term), availableWidth)
            if x > 0, x + width > availableWidth {
                x = 0
                y += chipHeight + lineSpacing
            }
            frames.append(.init(frame: CGRect(x: x, y: y, width: width, height: chipHeight)))
            x += width + interItemSpacing
        }

        let height = terms.isEmpty ? 0 : y + chipHeight
        return (frames, height)
    }
}

// MARK: - UITextFieldDelegate

extension SearchOverlayViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submit(textField.text ?? "")
        return true
    }
}

// MARK: - UICollectionViewDelegate

extension SearchOverlayViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath) {
        case let .query(text): submit(text)
        case let .term(term): submit(term)
        case let .trending(_, title): submit(title)
        case .skeleton, .none: break
        }
    }
}

// MARK: - Section header

private final class SectionHeaderView: UICollectionReusableView {
    static let id = "SectionHeaderView"

    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.textColor = .textSecondary
        actionButton.setTitleColor(.accent, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(fire), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, UIView(), actionButton])
        stack.alignment = .firstBaseline
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String?, actionTitle: String?, action: (() -> Void)?) {
        // A tracked, uppercase label — the app's small-caps section style.
        titleLabel.attributedText = title.map {
            NSAttributedString(string: $0.uppercased(), attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.textSecondary,
                .kern: 0.8
            ])
        }
        self.action = action
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
    }

    @objc private func fire() { action?() }
}

// MARK: - Cells

/// Bottom hairline shared by the plain rows. The caller pins it, insetting the leading
/// edge to the text so it doesn't run under the row's icon.
private func makeRowSeparator() -> UIView {
    let separator = UIView()
    separator.backgroundColor = .hairline
    separator.translatesAutoresizingMaskIntoConstraints = false
    return separator
}

private final class QueryRowCell: UICollectionViewCell {
    static let id = "QueryRowCell"

    private let iconView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.image = UIImage(systemName: "magnifyingglass")
        iconView.tintColor = .accent
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .textPrimary

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let separator = makeRowSeparator()
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted ? .surface : .clear }
    }

    func configure(query: String) {
        label.text = "Search for “\(query)”"
    }
}

private final class TermRowCell: UICollectionViewCell {
    static let id = "TermRowCell"

    private let iconView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.image = UIImage(systemName: "clock.arrow.circlepath")
        iconView.tintColor = .textSecondary
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .textPrimary

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let separator = makeRowSeparator()
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 34),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted ? .surface : .clear }
    }

    func configure(_ term: String) {
        label.text = term
    }
}

private final class TrendingRowCell: UICollectionViewCell {
    static let id = "TrendingRowCell"

    private let rankLabel = UILabel()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let rounded = UIFont.systemFont(ofSize: 15, weight: .semibold)
        rankLabel.font = UIFont(descriptor: rounded.fontDescriptor.withDesign(.rounded) ?? rounded.fontDescriptor, size: 15)
        rankLabel.textAlignment = .center
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)

        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .textPrimary

        let stack = UIStackView(arrangedSubviews: [rankLabel, label])
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let separator = makeRowSeparator()
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 24),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 38),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted ? .surface : .clear }
    }

    func configure(rank: Int, title: String) {
        rankLabel.text = "\(rank)"
        // The top three carry the accent; the rest stay in the neutral ramp.
        rankLabel.textColor = rank <= 3 ? .accent : .textSecondary
        label.text = title
    }
}

private final class SkeletonRowCell: UICollectionViewCell {
    static let id = "SkeletonRowCell"

    private let bar = UIView()
    private var widthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        bar.backgroundColor = .surface
        bar.layer.cornerRadius = 7
        bar.layer.cornerCurve = .continuous
        bar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bar)

        widthConstraint = bar.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bar.heightAnchor.constraint(equalToConstant: 14),
            widthConstraint
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        bar.layer.removeAllAnimations()
        bar.alpha = 1
    }

    func configure(index: Int) {
        // Varying widths so the stack reads as lines of text, not a repeated block —
        // the same idea as `SkeletonGridView`.
        let fractions: [CGFloat] = [0.7, 0.45, 0.8, 0.55, 0.72, 0.5]
        widthConstraint.isActive = false
        widthConstraint = bar.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: fractions[index % fractions.count])
        widthConstraint.isActive = true

        // A slow pulse rather than a shimmer sweep — matches the app's loading idiom.
        UIView.animate(
            withDuration: 0.9, delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]
        ) {
            self.bar.alpha = 0.4
        }
    }
}

private final class ChipCell: UICollectionViewCell {
    static let id = "ChipCell"

    var onDelete: (() -> Void)?

    private static let font = UIFont.systemFont(ofSize: 14, weight: .medium)
    private static let leadingPadding: CGFloat = 14
    private static let labelToButtonGap: CGFloat = 6
    private static let buttonSize: CGFloat = 16
    private static let trailingPadding: CGFloat = 12

    private let label = UILabel()
    private let deleteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .surface
        contentView.layer.cornerRadius = 17
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.hairline.cgColor

        label.font = Self.font
        label.textColor = .textPrimary

        deleteButton.setImage(
            UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)),
            for: .normal
        )
        deleteButton.tintColor = .textSecondary
        deleteButton.setContentHuggingPriority(.required, for: .horizontal)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, deleteButton])
        stack.spacing = Self.labelToButtonGap
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingPadding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.trailingPadding),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Self.buttonSize)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.6 : 1 }
    }

    func configure(_ text: String) {
        label.text = text
    }

    @objc private func deleteTapped() { onDelete?() }

    /// The width the wrapping layout should reserve for this term — must track the
    /// constraints above.
    static func width(for text: String) -> CGFloat {
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return ceil(textWidth) + leadingPadding + labelToButtonGap + buttonSize + trailingPadding
    }
}
