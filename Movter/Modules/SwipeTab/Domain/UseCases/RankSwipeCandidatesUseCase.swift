//
//  RankSwipeCandidatesUseCase.swift
//  Movter
//
//  Created by Nurtore on 21.11.2026.
//

import Foundation

protocol RankSwipeCandidatesUseCase {
    func execute(candidates: [Media], tasteProfile: UserTasteProfile) -> [Media]
}

final class DefaultRankSwipeCandidatesUseCase: RankSwipeCandidatesUseCase {

    private static let bayesianWeight: Double = 250.0
    private static let bayesianPriorMean: Double = 6.8
    private static let primaryGenreClumpPenalty: Double = 0.25
    private static let titlePrefixClumpPenalty: Double = 0.20

    func execute(candidates: [Media], tasteProfile: UserTasteProfile) -> [Media] {
        guard candidates.count > 1 else { return candidates }

        var remaining = candidates
            .map { (media: $0, baseScore: Self.baseScore(for: $0, profile: tasteProfile)) }
            .sorted { lhs, rhs in
                if lhs.baseScore != rhs.baseScore {
                    return lhs.baseScore > rhs.baseScore
                }
                return lhs.media.id < rhs.media.id
            }

        var ordered: [Media] = []
        ordered.reserveCapacity(remaining.count)
        ordered.append(remaining.removeFirst().media)

        while !remaining.isEmpty {
            let previous = ordered[ordered.count - 1]
            var bestIndex = 0
            var bestAdjustedScore = -Double.infinity

            for index in remaining.indices {
                let candidate = remaining[index]
                let penalty = Self.samePrimaryGenrePenalty(candidate.media, previous)
                    + Self.sameTitlePrefixPenalty(candidate.media, previous)
                let adjustedScore = candidate.baseScore - penalty
                if index == 0 || adjustedScore > bestAdjustedScore {
                    bestAdjustedScore = adjustedScore
                    bestIndex = index
                }
            }

            ordered.append(remaining.remove(at: bestIndex).media)
        }

        return ordered
    }

    static func bayesianRating(for media: Media) -> Double {
        let v = Double(max(0, media.voteCount ?? 0))
        let r = media.voteAverage
        return (v / (v + bayesianWeight)) * r + (bayesianWeight / (v + bayesianWeight)) * bayesianPriorMean
    }

    static func genreAffinity(for media: Media, profile: UserTasteProfile) -> Double {
        guard let genreIDs = media.genreIds, !genreIDs.isEmpty else {
            return 0.0
        }
        let sum = genreIDs.reduce(0.0) { partial, genreID in
            partial + (profile.genreAffinities[genreID] ?? 0.0)
        }
        return clampUnit(sum / Double(genreIDs.count))
    }

    static func decadeAffinity(for media: Media, profile: UserTasteProfile) -> Double {
        guard let decade = UserTasteProfile.decade(from: media.year) else {
            return 0.0
        }
        return clampUnit(profile.decadeAffinities[decade] ?? 0.0)
    }

    static func baseScore(for media: Media, profile: UserTasteProfile) -> Double {
        let genre = genreAffinity(for: media, profile: profile)
        let rating = bayesianRating(for: media) / 10.0
        let decade = decadeAffinity(for: media, profile: profile)
        let cooldownPenalty = profile.previouslyPassedIDs.contains(media.id) ? 0.10 : 0.0
        return (0.45 * genre) + (0.35 * rating) + (0.20 * decade) - cooldownPenalty
    }

    static func samePrimaryGenrePenalty(_ lhs: Media, _ rhs: Media) -> Double {
        guard let g1 = lhs.genreIds?.first, let g2 = rhs.genreIds?.first, g1 == g2 else {
            return 0.0
        }
        return primaryGenreClumpPenalty
    }

    static func sameTitlePrefixPenalty(_ lhs: Media, _ rhs: Media) -> Double {
        let leftTitle = normalizedTitle(for: lhs)
        let rightTitle = normalizedTitle(for: rhs)
        guard !leftTitle.isEmpty, !rightTitle.isEmpty else { return 0.0 }

        if leftTitle.commonPrefix(with: rightTitle).count >= 6 {
            return titlePrefixClumpPenalty
        }

        let leftStem = titleDelimiterStem(from: leftTitle)
        let rightStem = titleDelimiterStem(from: rightTitle)
        if leftStem.count >= 4, leftStem == rightStem {
            return titlePrefixClumpPenalty
        }

        let leftWord = firstSignificantWord(from: leftTitle)
        let rightWord = firstSignificantWord(from: rightTitle)
        if leftWord.count >= 4, leftWord == rightWord {
            return titlePrefixClumpPenalty
        }

        return 0.0
    }

    private static func clampUnit(_ value: Double) -> Double {
        min(1.0, max(-1.0, value))
    }

    private static func normalizedTitle(for media: Media) -> String {
        var title = media.displayName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        for article in ["the ", "a ", "an "] {
            if title.hasPrefix(article) {
                title = String(title.dropFirst(article.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        return title
    }

    private static func titleDelimiterStem(from normalizedTitle: String) -> String {
        if let colonIndex = normalizedTitle.firstIndex(of: ":") {
            let prefix = String(normalizedTitle[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !prefix.isEmpty {
                return prefix
            }
        }
        if let dashRange = normalizedTitle.range(of: " - ") {
            let prefix = String(normalizedTitle[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !prefix.isEmpty {
                return prefix
            }
        }
        if let dashIndex = normalizedTitle.firstIndex(of: "-") {
            let prefix = String(normalizedTitle[..<dashIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if prefix.count >= 4 {
                return prefix
            }
        }
        return normalizedTitle
    }

    private static func firstSignificantWord(from normalizedTitle: String) -> String {
        let components = normalizedTitle.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components.first(where: { !$0.isEmpty }) ?? ""
    }
}
