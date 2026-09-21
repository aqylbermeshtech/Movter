//
//  SearchBar.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import SwiftUI

public struct SearchBar: View {
    private enum Constants {
        static let fieldPadding: CGFloat = 12
        static let iconSize: CGFloat = 20
        static let smallIconSize: CGFloat = 16
        static let fieldCornerRadius: CGFloat = 100
    }
    
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    let onSearchTextChanged: (String) -> Void
    let onCancelTapped: () -> Void

    public init(
        searchText: Binding<String>,
        onSearchTextChanged: @escaping (String) -> Void = { _ in },
        onCancelTapped: @escaping () -> Void = {}
    ) {
        self._searchText = searchText
        self.onSearchTextChanged = onSearchTextChanged
        self.onCancelTapped = onCancelTapped
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                ImageAsset.searchIcon.swiftUIImage
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                TextField("", text: $searchText, prompt: Text(LocalizedString.Search.placeholder).foregroundColor(.searchPlaceholder))
                    .font(Typography.inputText)
                    .foregroundColor(.searchText)
                    .keyboardType(.default)
                    .focused($isFocused)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { newValue in
                        onSearchTextChanged(newValue)
                    }
                    .onSubmit {

                    }

                if searchText.isEmpty {
                    Button(action: {
                    }) {
                        ImageAsset.voiceIcon.swiftUIImage
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.smallIconSize, height: Constants.smallIconSize)
                            .foregroundColor(.searchIcon)
                    }
                } else {
                    Button(action: {
                        searchText = ""
                        onSearchTextChanged("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.searchIcon)
                            .font(Typography.medium16)
                    }
                }
            }
            .padding(Constants.fieldPadding)
            .background(Color.searchBackground)
            .cornerRadius(Constants.fieldCornerRadius)

            Button(action: {
                searchText = ""
                onSearchTextChanged("")
                onCancelTapped()
                isFocused = false
            }) {
                Text(LocalizedString.cancel)
                    .font(Typography.cancelButton)
                    .foregroundColor(Color.primary)
            }
        }
        .animation(.easeInOut(duration: Spacing.animationFast), value: searchText.isEmpty)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        SearchBar(
            searchText: .constant(""),
            onSearchTextChanged: { text in
                print("Search text changed: \(text)")
            },
            onCancelTapped: {
                print("Cancel tapped")
            }
        )
    }
    .padding()
    .background(Color.background)
}
