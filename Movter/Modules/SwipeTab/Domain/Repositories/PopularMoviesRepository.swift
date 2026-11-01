//
//  PopularMoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol PopularMoviesRepository {
    func fetchPopularMovies(page: Int) async throws -> MediaPage
}

