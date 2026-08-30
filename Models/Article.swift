//
//  Article.swift
//  Movter
//
//  Created by Nurtore on 02.05.2026.
//

import Foundation

nonisolated struct GuardianResponse: Codable {
    let response: GuardianContent
}

nonisolated struct GuardianContent: Codable {
    let results: [Article]
}

nonisolated struct Article: Codable {
    let id: String
    let webTitle: String
    let webUrl: String
    let fields: ArticleFields?
    var title: String { webTitle }
    
    var description: String {
        return fields?.trailText?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
    }
    var thumbnailURL: String? {
        return fields?.thumbnail
    }
}

nonisolated struct ArticleFields: Codable {
    let thumbnail: String?
    let trailText: String?
}
