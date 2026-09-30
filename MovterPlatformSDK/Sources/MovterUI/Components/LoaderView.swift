//
//  LoaderView.swift
//  Movter
//
//  Created by Nurtore on 01.10.2026.
//

import SwiftUI
import SwiftfulLoadingIndicators

// MARK: - InlineLoadingIndicator

public struct InlineLoadingIndicator: View {
    public init() {}

    public var body: some View {
        LoadingIndicator(animation: .circleTrim, color: Color.primary, size: .medium, speed: .normal)
    }
}

// MARK: - LoaderContent

public struct LoaderContent: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            InlineLoadingIndicator()
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - LoaderView

public struct LoaderView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            LoaderContent()
        }
    }
}

// MARK: - View Extension for Loader

public extension View {
    
    func loader(isPresented: Binding<Bool>) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                LoaderView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
            }
        }
    }
}
