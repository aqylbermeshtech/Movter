//
//  CountryListScreen.swift
//  Movter
//
//  Created by Nurtore on 23.09.2026.
//

import SwiftUI
//import MovterUI
//import MovterDomain

public struct CountryListScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    private let viewModel: CountryListViewModel
    private let onCountrySelected: (Country) -> Void
    
    init(viewModel: CountryListViewModel, onCountrySelected: @escaping (Country) -> Void) {
        self.viewModel = viewModel
        self.onCountrySelected = onCountrySelected
    }
    
    public var body: some View {
        CountryListView(viewModel: viewModel) { selectedCountry in
            onCountrySelected(selectedCountry)
        }
    }
}

