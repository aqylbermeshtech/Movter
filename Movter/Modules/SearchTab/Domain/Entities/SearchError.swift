//
//  SearchError.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum SearchError: LocalizedError, Equatable {
    case queryTooShort(min: Int)
    case offline
    case emptyResults
    case unsupportedCategory
    case invalidPage(_ page: Int)
}
