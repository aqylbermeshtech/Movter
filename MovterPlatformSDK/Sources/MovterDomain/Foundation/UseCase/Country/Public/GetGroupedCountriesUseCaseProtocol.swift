//
//  GetGroupedCountriesUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import Foundation
//import MentorNetwork

public protocol GetGroupedCountriesUseCaseProtocol {
    func execute(searchQuery: String) -> [(String, [CountryDTO])]
}

