//
//  ProfileViewModel.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import Foundation

@MainActor
final class ProfileViewModel2 {

    // MARK: - Dependencies

    private let getProfileUseCase: any GetProfileUseCase

    // MARK: - State

    private(set) var state: ProfileViewState = .loading {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((ProfileViewState) -> Void)?

    // MARK: - Initialization

    init(getProfileUseCase: any GetProfileUseCase) {
        self.getProfileUseCase = getProfileUseCase
    }

    // MARK: - Actions

    func loadProfile() async {
        state = .loading
        do {
            let user = try await getProfileUseCase.execute()
            state = .loaded(user)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
