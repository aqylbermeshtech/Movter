//
//  CountryRepositoryImpl.swift
//  Movter
//
//  Created by Nurtore on 03.10.2026.
//

import Foundation
//import MentorNetwork

nonisolated public final class CountryRepositoryImpl: CountryRepositoryProtocol {
    private let dataSource: CountryDataSourceProtocol
    private var countries: [CountryDTO]?
    
    public init(dataSource: CountryDataSourceProtocol) {
        self.dataSource = dataSource
    }
    
    private func ensureCountriesLoaded() {
        guard countries == nil else { return }
        countries = dataSource.loadCountries() ?? []
    }
    
    public func getAllCountries() -> [CountryDTO] {
        ensureCountriesLoaded()
        return (countries ?? []).sorted { $0.name < $1.name }
    }
    
    public func searchCountries(query: String) -> [CountryDTO] {
        guard !query.isEmpty else {
            return getAllCountries()
        }
        
        ensureCountriesLoaded()
        let lowercasedQuery = query.lowercased()
        return (countries ?? []).filter { country in
            country.name.lowercased().contains(lowercasedQuery) ||
            country.dialCode.contains(query) ||
            country.id.lowercased().contains(lowercasedQuery)
        }.sorted { $0.name < $1.name }
    }
    
    public func getCountryByCode(code: String) -> CountryDTO? {
        ensureCountriesLoaded()
        return countries?.first { $0.dialCode == code }
    }
    
    public func getCountryById(id: String) -> CountryDTO? {
        ensureCountriesLoaded()
        return countries?.first { $0.id == id }
    }
    
    public func getGroupedCountries(searchQuery: String) -> [(String, [CountryDTO])] {
        let filtered = searchQuery.isEmpty ? getAllCountries() : searchCountries(query: searchQuery)
        
        let grouped = Dictionary(grouping: filtered) { country in
            String(country.name.prefix(1).uppercased())
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
}

