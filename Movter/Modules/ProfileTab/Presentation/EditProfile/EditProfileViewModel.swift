//
//  EditProfileViewModel.swift
//  Movter
//
//  Created by Nurtore on 18.08.2026.
//

import Foundation

@MainActor
final class EditProfileViewModel {

    static let maxNameLength = 50

    // MARK: - Dependencies

    private let getProfileUseCase: GetProfileUseCase
    private let updateProfileUseCase: UpdateProfileUseCase

    // MARK: - State

    private(set) var initialName: String = ""
    private(set) var currentName: String = ""
    private(set) var email: String = ""
    private(set) var avatarURL: URL?

    private(set) var isLoading: Bool = false
    private(set) var isSaving: Bool = false

    var onStateChange: (() -> Void)?

    var trimmedName: String {
        currentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasUnsavedChanges: Bool {
        trimmedName != initialName
    }

    var isValidName: Bool {
        !trimmedName.isEmpty && trimmedName.count <= Self.maxNameLength
    }

    var canSave: Bool {
        isValidName && hasUnsavedChanges && !isSaving
    }

    // MARK: - Initialization

    init(
        getProfileUseCase: GetProfileUseCase,
        updateProfileUseCase: UpdateProfileUseCase
    ) {
        self.getProfileUseCase = getProfileUseCase
        self.updateProfileUseCase = updateProfileUseCase
    }

    // MARK: - Actions

    func loadProfile() async {
        isLoading = true
        onStateChange?()

        do {
            let profile = try await getProfileUseCase.execute()
            self.initialName = profile.name
            self.currentName = profile.name
            self.email = profile.email
            self.avatarURL = profile.avatarURL
        } catch {
            // Keep existing values on failure
        }

        isLoading = false
        onStateChange?()
    }

    func updateCurrentName(_ newName: String) {
        self.currentName = newName
        onStateChange?()
    }

    func save() async throws {
        guard canSave else { return }
        isSaving = true
        onStateChange?()

        defer {
            isSaving = false
            onStateChange?()
        }

        try await updateProfileUseCase.execute(name: trimmedName, avatarURL: avatarURL)
        initialName = trimmedName
    }
}
