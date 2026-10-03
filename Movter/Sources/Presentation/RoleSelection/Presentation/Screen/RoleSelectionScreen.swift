//
//  RoleSelectionScreen.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import SwiftUI
//import MentorUI
//import MentorDomain

struct RoleSelectionScreen: View {
    private enum Constants {
        static let cardSpacing: CGFloat = 16
        static let cardTopPadding: CGFloat = 16
        static let hintsStartDelay: TimeInterval = 0.6
    }

    @ObservedObject var viewModel: RoleSelectionViewModel
    @State private var hintsController: ScreenCoachMarksController?

    var body: some View {
        ZStack {
            Color.backgroundCode
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Constants.cardSpacing) {
                    Text(LocalizedString.RoleSelection.subtitle)
                        .font(Typography.regular14)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)

                    ForEach(viewModel.roles) { role in
                        RoleCard(
                            role: role,
                            isSelected: viewModel.isSelected(role)
                        ) {
                            viewModel.selectRole(role)
                        }
                        .coachMarkAnchor(anchorId(for: role))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Constants.cardTopPadding)
                .padding(.bottom, Spacing.md)
            }
        }
        .navigationBar(
            title: LocalizedString.RoleSelection.title,
            onBackButtonTap: { viewModel.goBack() }
        )
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .loader(isPresented: $viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
        .environmentObject(viewModel.viewManager)
        .onAppear {
            startHintsIfNeeded()
        }
    }

    private func anchorId(for role: UserRole) -> String {
        switch role {
        case .mentee:
            return CoachMarkAnchorID.roleMentee
        case .mentor:
            return CoachMarkAnchorID.roleMentor
        }
    }

    private func startHintsIfNeeded() {
        guard !CoachMarksStore.hasSeenRoleSelectionHints else { return }
        guard hintsController == nil else { return }

        let controller = ScreenCoachMarksController(
            steps: CoachMarksContent.roleSelectionSteps(
                languageCode: LanguageManager.shared.currentLanguage.code
            ),
            onFinish: {
                CoachMarksStore.markRoleSelectionHintsSeen()
                hintsController = nil
            }
        )
        hintsController = controller

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.hintsStartDelay) {
            controller.start()
        }
    }

    private var actionBar: some View {
        ContinueButton(
            title: LocalizedString.RoleSelection.Button.start,
            action: viewModel.canContinue
        ) {
            viewModel.handleContinue()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color.backgroundCode)
    }
}

