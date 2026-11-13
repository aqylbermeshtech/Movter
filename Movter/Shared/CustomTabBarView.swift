//
//  CustomTabBarView.swift
//  Movter
//
//  Created by Nurtore on 25.08.2026.
//

import Combine
import SwiftUI

@MainActor
final class TabBarSelectionModel: ObservableObject {
    @Published var selectedIndex: Int = 0
}

struct CustomTabBarView: View {

    struct Tab: Hashable {
        let title: String
        let systemImage: String
    }

    static let preferredHeight: CGFloat = 55
    private static let elementSpacing: CGFloat = 10

    let tabs: [Tab]
    @ObservedObject var model: TabBarSelectionModel
    var onTabSelected: ((Int) -> Void)?
    var onSearchTapped: (() -> Void)?

    var body: some View {
        GlassEffectContainer(spacing: Self.elementSpacing) {
            HStack(spacing: Self.elementSpacing) {
                MorphingTabBar(
                    tabs: tabs,
                    activeIndex: $model.selectedIndex,
                    onTabSelected: onTabSelected
                )
                .zIndex(0)

                Button {
                    onSearchTapped?()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .label))
                        .frame(width: Self.preferredHeight, height: Self.preferredHeight)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .tint(Color(uiColor: .label))
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel("Search")
                .zIndex(1)
            }
            .frame(height: Self.preferredHeight)
        }
    }
}

struct MorphingTabBar: View {
    let tabs: [CustomTabBarView.Tab]
    @Binding var activeIndex: Int
    var barTint: Color = Color(uiColor: .label).opacity(0.12)
    var onTabSelected: ((Int) -> Void)?

    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                let isActive = activeIndex == index

                Button {
                    guard activeIndex != index else { return }
                    withAnimation(.smooth(duration: 0.45, extraBounce: 0)) {
                        activeIndex = index
                    }
                    onTabSelected?(index)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 19, weight: .medium))
                            .symbolEffect(.bounce, value: isActive)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .symbolVariant(isActive ? .fill : .none)
                    .foregroundStyle(isActive ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.capsule)
                    .background {
                        if isActive {
                            Capsule()
                                .fill(barTint)
                                .matchedGeometryEffect(id: "ACTIVE_TAB_PILL", in: tabAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.85)),
                    removal: .scale(scale: 0.01, anchor: .leading).combined(with: .opacity)
                ))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
            }
        }
        .padding(4)
        .clipShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
