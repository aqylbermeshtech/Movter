//
//  RoleSelectionViewModel.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
import Combine
//import MentorDomain

final class RoleSelectionViewModel: ObservableObject {

    let roles = UserRole.allCases
    let viewManager = RoleSelectionViewManager()

    private let submitRoleUseCase: SubmitRoleSelectionUseCaseProtocol
    private let output: RoleSelectionOutput
    private var cancellables = Set<AnyCancellable>()

    @Published var selectedRole: UserRole?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var canContinue: Bool {
        selectedRole != nil
    }

    init(submitRoleUseCase: SubmitRoleSelectionUseCaseProtocol, output: RoleSelectionOutput) {
        self.submitRoleUseCase = submitRoleUseCase
        self.output = output
        setupSelectedRoleObserver()
    }

    func onViewAppear() {
        viewManager.delegate = self
    }

    func isSelected(_ role: UserRole) -> Bool {
        selectedRole == role
    }

    func selectRole(_ role: UserRole) {
        if selectedRole == role {
            selectedRole = nil
            viewManager.setSelectedRole(nil)
        } else {
            selectedRole = role
            viewManager.selectRole(role)
        }
    }

    func handleContinue() {
        guard let role = selectedRole else { return }
        submitRoleAndContinue(userType: role.rawValue)
    }

    func goBack() {
        output.onBack()
    }

    private func submitRoleAndContinue(userType: String) {
        isLoading = true
        AnalyticsTracker.track(.onboardingRoleSelected(role: userType))

        Task { @MainActor in
            do {
                let response = try await submitRoleUseCase.execute(userType: userType)
                if response.success {
                    output.onRoleSelected(selectedRole!)
                } else {
                    errorMessage = response.message ?? "Ошибка сохранения роли"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func setupSelectedRoleObserver() {
        viewManager.$selectedRole
            .sink { [weak self] role in
                guard let self = self, self.selectedRole != role else { return }
                self.selectedRole = role
            }
            .store(in: &cancellables)
    }
}

extension RoleSelectionViewModel: RoleSelectionViewManagerDelegate {

    func onSelectRole(_ role: UserRole) {
        selectRole(role)
    }

    func onContinue() {
        handleContinue()
    }
}

