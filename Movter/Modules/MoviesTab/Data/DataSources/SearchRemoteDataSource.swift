//
//  SearchRemoteDataSource.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol SearchRemoteDataSource: AnyObject {
    func searchMovies(query: String, page: Int) async throws -> MediaPage
    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage
    func fetchTrending(page: Int) async throws -> MediaPage
}

final class DefaultSearchRemoteDataSource: SearchRemoteDataSource {
    private let service: MediaFetching
    
    init(service: MediaFetching = TMDBService.shared) {
        self.service = service
    }
    
    func searchMovies(query: String, page: Int) async throws -> MediaPage {
        try await service.searchMovies(query: query, page: page)
    }
    
    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        try await service.fetchDiscover(query: query, page: page)
    }
    
    func fetchTrending(page: Int = 1) async throws -> MediaPage {
        try await service.fetchDiscover(query: .trendingToday, page: page)
    }
}
