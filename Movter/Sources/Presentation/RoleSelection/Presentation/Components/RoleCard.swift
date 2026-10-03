//
//  RoleCard.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import SwiftUI
//import MentorUI

struct RoleCard: View {
    private enum Constants {
        static let imageHeight: CGFloat = 150
        static let contentPadding: CGFloat = 12
        static let cardHeight: CGFloat = 280
        static let benefitIconSize: CGFloat = 11
        static let cornerRadius: CGFloat = 10
        static let tagHorizontalPadding: CGFloat = 10
        static let tagVerticalPadding: CGFloat = 6
        static let tagCornerRadius: CGFloat = 35
    }

    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Image(role.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: Constants.imageHeight)
                        .frame(maxWidth: .infinity)

                    roleTag
                        .padding(.top, Constants.contentPadding)
                        .padding(.leading, Constants.contentPadding)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(role.title)
                        .font(Typography.roleCardTitle)
                        .foregroundColor(.textPrimary)

                    Text(role.subtitle)
                        .font(Typography.roleCardSubtitle)
                        .foregroundColor(.textPlaceholderActive)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(role.benefits, id: \.self) { benefit in
                            benefitRow(benefit)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(.horizontal, Constants.contentPadding)
                .padding(.bottom, Constants.contentPadding)
            }
            .frame(minHeight: Constants.cardHeight, alignment: .top)
            .background(Color.background)
            .cornerRadius(Constants.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(isSelected ? Color.buttonPrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "checkmark")
                .font(.system(size: Constants.benefitIconSize, weight: .semibold))
                .foregroundColor(.buttonPrimary)
                .frame(width: Constants.benefitIconSize, height: Constants.benefitIconSize)
                .padding(.top, Spacing.xxs)

            Text(text)
                .font(Typography.regular13)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }

    private var roleTag: some View {
        Text(role.tagTitle)
            .font(Typography.regular13)
            .foregroundColor(isSelected ? .buttonPrimary : .textPlaceholderActive)
            .padding(.horizontal, Constants.tagHorizontalPadding)
            .padding(.vertical, Constants.tagVerticalPadding)
            .background(isSelected ? Color.selectedSlotBackground : Color.tagBackground)
            .cornerRadius(Constants.tagCornerRadius)
    }
}


