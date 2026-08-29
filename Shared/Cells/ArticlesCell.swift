//
//  ArticlesCell.swift
//  Movter
//
//  Created by Nurtore on 02.05.2026.
//

import UIKit


final class ArticlesCell: UICollectionViewCell {
    static let identifier = "ArticlesCell"

    /// Guards against a slow thumbnail landing in a cell that has been reused.
    private var imageURL: URL?
    private let articleImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let titleLabel:UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 2
        label.textColor = .textPrimary
        return label
    }()
    private let descriptionLabel:UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 3
        label.textColor = .textSecondary
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .surface
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        
        [articleImageView, titleLabel, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            articleImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            articleImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            articleImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            articleImageView.heightAnchor.constraint(equalToConstant: 240),
            
            titleLabel.topAnchor.constraint(equalTo: articleImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        articleImageView.image = nil
        imageURL = nil
    }

    func configure(with article: Article) {
        titleLabel.text = article.webTitle
        descriptionLabel.text = article.description

        articleImageView.image = nil
        guard let urlString = article.thumbnailURL, let url = URL(string: urlString) else {
            imageURL = nil
            return
        }
        imageURL = url
        ImageLoader.load(url: url) { [weak self] image in
            guard let self = self, self.imageURL == url else { return }
            self.articleImageView.image = image
        }
    }
}
