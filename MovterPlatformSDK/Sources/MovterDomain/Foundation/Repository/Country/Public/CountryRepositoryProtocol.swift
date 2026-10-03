//
//  CountryRepositoryProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

public protocol CountryRepositoryProtocol {
    func getAllCountries() -> [CountryDTO]
    func searchCountries(query: String) -> [CountryDTO]
    func getCountryByCode(code: String) -> CountryDTO?
    func getCountryById(id: String) -> CountryDTO?
    func getGroupedCountries(searchQuery: String) -> [(String, [CountryDTO])]
}
