//
//  CountryDTO.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import Foundation

public struct CountriesResponseDTO: Codable {
    public let countries: [CountryDTO]
}

public struct CountryDTO: Codable {
    public let id: String
    public let name: String
    public let dialCode: String
    public let flag:String
}
