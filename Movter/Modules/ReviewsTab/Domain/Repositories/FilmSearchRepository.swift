//
//  FilmSearchRepository.swift
//  Movter
//
//  Created by Nurtore on 01.11.2026.
//

import Foundation

protocol FilmSearchRepository {
    func searchFilms(query: String, page: Int) async throws -> [Media]
}
