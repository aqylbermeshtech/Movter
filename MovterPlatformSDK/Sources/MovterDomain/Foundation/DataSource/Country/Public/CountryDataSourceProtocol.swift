//
//  CountryDataSourceProtocol.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation

public protocol CountryDataSourceProtocol {
    func loadCountries() -> [CountryDTO]?
}
