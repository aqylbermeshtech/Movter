//
//  CountryLocalDataSource.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public final class CountryLocalDataSource: CountryDataSourceProtocol {
    
    private let bundle: Bundle
    
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    public func loadCountries() -> [CountryDTO]? {
        guard let url = bundle.url(forResource: "countries", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let countries = try decoder.decode([CountryDTO].self, from: data)
            return countries
        } catch {
            return nil
        }
    }
}
