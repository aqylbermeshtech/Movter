//
//  CloseButton.swift
//  Movter
//
//  Created by Nurtore on 30.09.2026.
//

import SwiftUI

public struct CloseButton: View {
    public enum Style {
        case registration
        case `default`
    }
    
    private let style: Style
    private let action: () -> Void
    
    public init(style: Style, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }
    
    public var body: some View {
        Button(action: onTap) {
            buttonImage
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(LocalizedString.close))
    }
    
    private var buttonImage: Image {
        switch style {
        case .registration:
            return ImageAsset.closeButtonreg.swiftUIImage
        case .default:
            return ImageAsset.closeButton.swiftUIImage
        }
    }
    
    private func onTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        action()
    }
}
