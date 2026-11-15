//
//  FetchDiscoverQueryUseCase.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

enum DiscoverQueryError: LocalizedError {
    case invalidPage(Int)

    var errorDescription: String? {
        switch self {
        case .invalidPage(let page):
            return "Invalid page number: \(page)"
        }
    }
}

protocol FetchDiscoverQueryUseCase {
    func execute(query: DiscoverQuery, page: Int) async throws -> MediaPage
}

final class DefaultFetchDiscoverQueryUseCase: FetchDiscoverQueryUseCase {
    private let repository: SearchMoviesRepository
    
    init(repository: SearchMoviesRepository = DefaultSearchMoviesRepository()) {
        self.repository = repository
    }
    
    func execute(query: DiscoverQuery, page: Int = 1) async throws -> MediaPage {
        guard page >= 1 else {
            throw DiscoverQueryError.invalidPage(page)
        }
        
        return try await repository.fetchDiscover(query: query, page: page)
    }
}
