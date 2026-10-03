//
//  CountryDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public protocol CountryDataSourceProtocol {
    func loadCountries() -> [CountryDTO]?
}
