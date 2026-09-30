//
//  CountryListViewModel.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import Foundation
import Combine
//import MovterDomain
//import MovterNetwork

final class CountryListViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var groupedCountries: [(String, [Country])] = []
    @Published var isSearching: Bool = false
    
    private let getGroupedCountriesUseCase: GetGroupedCountriesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var onCountrySelected: ((Country) -> Void)?
    var onCancel: (()->Void)?
    
    init(getGroupedCountriesUseCase: GetGroupedCountriesUseCaseProtocol) {
        self.getGroupedCountriesUseCase = getGroupedCountriesUseCase
        setupSearchObserver()
        loadCountries()
    }
    
    func selectCountry(_ country: Country) {
        onCountrySelected?(country)
    }
    
    func cancel() {
        onCancel?()
    }
    
    private func setupSearchObserver() {
        $searchQuery
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func loadCountries() {
        let dtoGroups = getGroupedCountriesUseCase.execute(searchQuery:"")
        groupedCountries = dtoGroups.map { (key, dtos) in
            (key, dtos.map { Country(dto: $0) })
        }
    }
    
    private func performSearch(query: String) {
        let dtoGroups = getGroupedCountriesUseCase.execute(searchQuery: query)
        groupedCountries = dtoGroups.map { (key, dtos) in
            (key, dtos.map { Country(dto: $0) })
        }
    }

    var sectionTitles: [String] {
        groupedCountries.map { $0.0 }
    }
}
