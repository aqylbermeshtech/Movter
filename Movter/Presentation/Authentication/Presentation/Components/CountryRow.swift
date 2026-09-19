//
//  CountryRow.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import SwiftUI
//import MovterUI
//import MentorDomain

public struct CountryRow: View {
    private enum Constants {
        static let rowHeight: CGFloat = 56
    }
    
    let country: Country
    let onSelect: (Country) -> Void
    
    init(country: Country, onSelect: @escaping (Country) -> Void) {
        self.country = country
        self.onSelect = onSelect
    }
    
    public var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(country.flag)
                .font(Typography.emojiRow)
            
            Text(country.name)
                .font(Typography.bodyLarge)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(country.dialCode)
                .font(Typography.bodyLarge)
                .foregroundColor(.segmentTextInactive)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: Constants.rowHeight)
        .frame(maxWidth: .infinity)
        .background(Color.background)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(country)
        }
    }
}

public struct CountryListView: View {
    public enum Constants {
        static let grabberCornerRadius: CGFloat = 2.5
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = 8
        static let grabberContainerHeight: CGFloat = 20
        static let toolbarBottomPadding: CGFloat = 12
        static let dividerHeight: CGFloat = 1
        static let sectionHeaderHeight: CGFloat = 44
    }
    
    @StateObject private var viewModel: CountryListViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let onCountrySelected: (Country) -> Void
    
    init(viewModel: CountryListViewModel, onCountrySelected: @escaping (Country) -> Void) {
        self.onCountrySelected = onCountrySelected
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            grabberView
            
            toolbarView
            
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedCountries, id: \.0) { letter, countries in
                        Section(header: sectionHeader(letter: letter)) {
                            ForEach(countries) { country in
                                VStack(spacing: 0) {
                                    dividerView
                                    
                                    CountryRow(country: country) { selectedCountry in
                                        viewModel.selectedCountry(selectedCountry)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.background)
        }
        .background(Color.background)
        .onAppear {
            viewModel.onCountrySelected = onCountrySelected
            viewModel.onCancel = { dismiss() }
        }
    }
    
    private var grabberView: some View {
        VStack {
            RoundedRectangle(cornerRadius: Constants.grabberCornerRadius)
                .fill(Color.grabber)
                .frame(width: Constants.grabberWidth, height: Constants.grabberHeight)
                .padding(.top, Constants.grabberContainerHeight)
        }
        .frame(height: Constants.grabberContainerHeight)
    }
    
    private var toolbarView: some View {
        SearchBar(searchText: $viewModel.searchQuery, onSearchTextChanged: { _ in }, onCancelTapped: { viewModel.cancel() })
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Constants.toolbarBottomPadding)
    }
    
    private var dividerView: some View {
        Rectangle()
            .fill(Color.separatorVibrant)
            .frame(height: Constants.dividerHeight)
            .padding(.horizontal, Spacing.md)
    }
    
    private func sectionHeader(letter: String) -> some View {
        VStack(spacing: 0) {
            dividerView
            
            HStack {
                Text(letter)
                    .font(Typography.sectionHeader)
                    .foregroundColor(.segmentTextInactive)
                Spacer()
            }
            .frame(height: Constants.sectionHeaderHeight)
            .padding(.horizontal, Spacing.md)
            background(Color.background)
        }
    }
    
}
