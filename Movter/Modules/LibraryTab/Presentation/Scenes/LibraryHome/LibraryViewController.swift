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
        VStack(alignment: .leading, spacing: 20) {
            LibrarySearchBar(text: $viewModel.searchText)
                .padding(.horizontal, 16)

            LibraryFolderToggleBar(
                selectedFolder: viewModel.selectedFolder,
                onSelect: { folder in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.selectFolder(folder)
                    }
                }
            )
            .padding(.horizontal, 16)

            TabView(
                selection: $viewModel.selectedFolder.animation(.spring(response: 0.32, dampingFraction: 0.82))
            ) {
                ForEach(LibraryFolder.allCases) { folder in
                    folderPage(for: folder)
                        .tag(folder)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.top, 8)
        .background(Color(uiColor: .canvas).ignoresSafeArea())
    }

    @ViewBuilder
    private func folderPage(for folder: LibraryFolder) -> some View {
        let items = viewModel.items(for: folder)
        ScrollView(showsIndicators: false) {
            Group {
                if items.isEmpty {
                    LibraryEmptyFolderSpace()
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(items) { item in
                            Button {
                                viewModel.didSelectItem(item)
                            } label: {
                                LibraryPosterCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
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
        HStack(spacing: 6) {
            ForEach(LibraryFolder.allCases) { folder in
                let isSelected = folder == selectedFolder

                Button {
                    onSelect(folder)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: folder.symbol)
                            .font(.system(size: 17, weight: .bold))

                        if isSelected {
                            Text(folder.title)
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Color(uiColor: .textSecondary))
                    .frame(maxWidth: isSelected ? .infinity : nil)
                    .frame(width: isSelected ? nil : 43, height: 48)
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
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tv")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(Color(uiColor: .textSecondary))
                .padding(.bottom, 4)

            Text("No shows Yet")
                .font(Font(UIFont.emptyStateTitle))
                .foregroundStyle(Color(uiColor: .textPrimary))
                .multilineTextAlignment(.center)

            Text("Shows you add appear here. Find something to watch in Search.")
                .font(Font(UIFont.secondaryBody))
                .foregroundStyle(Color(uiColor: .textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 96)
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
