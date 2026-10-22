//
//  ProfileHeaderView.swift
//  Movter
//
//  Created by Nurtore on 23.10.2026.
//

import UIKit

final class ProfileHeaderView: UIView {
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .profileName
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let memberSinceLabel: UILabel = {
        let label = UILabel()
        label.font = .footnote
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    let statsView = ProfileStatsView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with user: UserProfile) {
        nameLabel.text = user.name
        
        if let memberSince = user.memberSinceDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy"
            memberSinceLabel.text = "Member since \(formatter.string(from: memberSince))"
            memberSinceLabel.isHidden = false
        } else {
            memberSinceLabel.isHidden = true
        }
        avatarImageView.image = InitialsAvatar.image(name: user.name, email: user.email, size: 200)
        statsView.configure(
            watched: user.stats.watchedCount,
            reviews: user.stats.reviewsCount,
            watchlist: user.stats.watchlistCount
        )
    }
    
    private func setupLayout() {
        statsView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        memberSinceLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(memberSinceLabel)
        addSubview(statsView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            avatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            memberSinceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            memberSinceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            memberSinceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statsView.topAnchor.constraint(equalTo: memberSinceLabel.bottomAnchor, constant: 16),
            statsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
}
