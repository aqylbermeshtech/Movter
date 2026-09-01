//
//  GenreChipGridView.swift
//  Movter
//
//  Created by Nurtore on 01.09.2026.
//

import UIKit

/// A block of genre chips that wraps onto as many lines as it needs.
///
/// Laid out by frame rather than by stacked stack views: the wrap depends on the
/// measured width of every title, and the same arithmetic has to answer "how tall is
/// this at width W?" before the view exists, so a table row can be sized for it.
final class GenreChipGridView: UIView {

    var onSelect: ((MovieGenre) -> Void)?

    private static let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    private static let chipHeight: CGFloat = 42
    /// Padding either side of a chip's title.
    private static let chipPadding: CGFloat = 20
    private static let spacing: CGFloat = 10

    private let genres: [MovieGenre]
    private var chips: [UIButton] = []

    init(genres: [MovieGenre] = MovieGenre.allCases) {
        self.genres = genres
        super.init(frame: .zero)
        for genre in genres {
            let chip = makeChip(for: genre)
            addSubview(chip)
            chips.append(chip)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        Self.layOut(genres, in: bounds.width) { index, frame in
            chips[index].frame = frame
        }
    }

    /// The height this needs at `width`. Runs the same wrap as `layoutSubviews`, which
    /// is the point — a measurement that can drift from the layout is worse than none.
    static func height(forWidth width: CGFloat, genres: [MovieGenre] = MovieGenre.allCases) -> CGFloat {
        var bottom: CGFloat = 0
        layOut(genres, in: width) { _, frame in bottom = max(bottom, frame.maxY) }
        return bottom
    }

    /// Walks the chips left to right, wrapping at `width`, and hands each one its frame.
    private static func layOut(
        _ genres: [MovieGenre],
        in width: CGFloat,
        body: (Int, CGRect) -> Void
    ) {
        guard width > 0 else { return }
        var x: CGFloat = 0
        var y: CGFloat = 0

        for (index, genre) in genres.enumerated() {
            let chipWidth = chipWidth(for: genre)
            // Wrap — unless the chip already starts a line, in which case it is simply
            // wider than the view and there is nowhere better to put it.
            if x > 0, x + chipWidth > width {
                x = 0
                y += chipHeight + spacing
            }
            body(index, CGRect(x: x, y: y, width: chipWidth, height: chipHeight))
            x += chipWidth + spacing
        }
    }

    private static func chipWidth(for genre: MovieGenre) -> CGFloat {
        let title = (genre.title as NSString).size(withAttributes: [.font: font]).width
        return ceil(title) + chipPadding * 2
    }

    private func makeChip(for genre: MovieGenre) -> UIButton {
        let chip = UIButton(type: .system)
        chip.setTitle(genre.title, for: .normal)
        chip.titleLabel?.font = Self.font
        chip.setTitleColor(.textPrimary, for: .normal)
        chip.backgroundColor = .surface
        chip.layer.cornerRadius = Self.chipHeight / 2
        chip.layer.cornerCurve = .continuous
        chip.addAction(UIAction { [weak self] _ in self?.onSelect?(genre) }, for: .touchUpInside)
        return chip
    }

    /// The chips are filled with `.surface` and titled in `.textPrimary`, both of which
    /// move with the appearance, so they are reapplied rather than left to resolve.
    func updateTheme() {
        for chip in chips {
            chip.backgroundColor = .surface
            chip.setTitleColor(.textPrimary, for: .normal)
        }
    }
}

/// The whole grid as one table row. The chips wrap, so they are a single cell rather
/// than a row each, and the cell's height is asked of the grid rather than self-sized.
final class GenreChipsCell: UITableViewCell {

    static let identifier = "GenreChipsCell"

    private static let verticalInset: CGFloat = 12
    private static let horizontalInset: CGFloat = 16

    let gridView = GenreChipGridView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // The chips are the surfaces here; a filled row behind them would leave them
        // invisible against their own background.
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        gridView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gridView)
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalInset),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalInset),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset),
            gridView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalInset)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func height(forTableWidth width: CGFloat) -> CGFloat {
        GenreChipGridView.height(forWidth: width - horizontalInset * 2) + verticalInset * 2
    }
}
