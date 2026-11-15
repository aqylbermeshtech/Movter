//
//  LibraryViewController.swift
//  Movter
//

import SwiftUI
import UIKit

@MainActor
final class LibraryViewController: UIHostingController<LibraryView> {
    private let viewModel: LibraryViewModel
    private let coordinator: LibraryCoordinator?

    init(viewModel: LibraryViewModel, coordinator: LibraryCoordinator? = nil) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(rootView: LibraryView(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Library"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .canvas
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadLibrary()
    }
}

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                LibrarySearchBar(text: $viewModel.searchText)

                LibraryFolderToggleBar(
                    selectedFolder: viewModel.selectedFolder,
                    onSelect: { folder in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.selectFolder(folder)
                        }
                    }
                )

                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.selectedFolder.sectionTitle)
                        .font(Font(UIFont.cardTitle))
                        .foregroundStyle(Color(uiColor: .textPrimary))

                    folderContentSpace
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .canvas).ignoresSafeArea())
    }

    @ViewBuilder
    private var folderContentSpace: some View {
        let items = viewModel.currentItems
        if items.isEmpty {
            LibraryEmptyFolderSpace(
                folder: viewModel.selectedFolder,
                searchQuery: viewModel.searchText
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(items) { item in
                    LibraryPosterCard(item: item)
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Search Bar

private struct LibrarySearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(uiColor: .textPrimary))

            TextField(
                "",
                text: $text,
                prompt: Text("Search your shows")
                    .foregroundColor(Color(uiColor: .textSecondary))
            )
            .font(Font(UIFont.body))
            .foregroundStyle(Color(uiColor: .textPrimary))
            .tint(Color(uiColor: .textPrimary))
            .focused($isFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(uiColor: .textSecondary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .surface))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color(uiColor: .hairline), lineWidth: 1)
        )
    }
}

// MARK: - Togglable Folder Variants Bar

private struct LibraryFolderToggleBar: View {
    let selectedFolder: LibraryFolder
    let onSelect: (LibraryFolder) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(LibraryFolder.allCases) { folder in
                let isSelected = folder == selectedFolder

                Button {
                    onSelect(folder)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: folder.symbol)
                            .font(.system(size: 18, weight: .bold))

                        if isSelected {
                            Text(folder.title)
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Color(uiColor: .textSecondary))
                    .frame(maxWidth: isSelected ? .infinity : nil)
                    .frame(width: isSelected ? nil : 50, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? folder.activeColor : Color(uiColor: .surface))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? Color.white.opacity(0.22)
                                    : Color(uiColor: .hairline),
                                lineWidth: 1
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Folder Content Space

private struct LibraryEmptyFolderSpace: View {
    let folder: LibraryFolder
    let searchQuery: String

    private var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .canvas))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(uiColor: .hairline), lineWidth: 1)
                    )

                Image(systemName: isSearching ? "magnifyingglass" : folder.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .textSecondary))
            }

            Text(isSearching ? "No Matching Shows" : folder.emptyTitle)
                .font(Font(UIFont.placeholderTitle))
                .foregroundStyle(Color(uiColor: .textPrimary))
                .multilineTextAlignment(.center)

            Text(
                isSearching
                    ? "Nothing in \(folder.title) matched \"\(searchQuery)\"."
                    : folder.emptySubtitle
            )
            .font(Font(UIFont.secondaryBody))
            .foregroundStyle(Color(uiColor: .textSecondary))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(uiColor: .hairline), lineWidth: 1)
        )
    }
}

private struct LibraryPosterCard: View {
    let item: LibraryMediaItem

    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Color(uiColor: .surface)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "film")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(uiColor: .textSecondary))
                }
            }
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(uiColor: .hairline), lineWidth: 0.8)
            )

            Text(item.title)
                .font(Font(UIFont.cellTitle))
                .foregroundStyle(Color(uiColor: .textPrimary))
                .lineLimit(1)

            if let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Font(UIFont.caption))
                    .foregroundStyle(Color(uiColor: .textSecondary))
                    .lineLimit(1)
            }
        }
        .task(id: item.id) {
            guard let url = item.posterURL else { return }
            image = await withCheckedContinuation { continuation in
                ImageLoader.load(url: url) { loaded in
                    continuation.resume(returning: loaded)
                }
            }
        }
    }
}
