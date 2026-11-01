//
//  MoviesRepository.swift
//  Movter
//
//  Created by Nurtore on 25.10.2026.
//

import Foundation

protocol MoviesRepository: Sendable {
    func fetchDiscover(genre: MovieGenre, page: Int) async throws -> [Media]
}
