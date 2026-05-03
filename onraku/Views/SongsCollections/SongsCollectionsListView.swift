//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct SongsCollectionsListView: View {
    var title: String
    @StateObject private var viewModel: SongsCollectionsListViewModel

    init(
        type: CollectionTypes,
        title: String,
        viewModel: SongsCollectionsListViewModel? = nil
    ) {
        self.title = title
        _viewModel = StateObject(
            wrappedValue: viewModel ?? SongsCollectionsListViewModel(type: type)
        )
    }

    var body: some View {
        List {
            if viewModel.loadState == .loading || viewModel.loadState == .initial {
                LoadingCellView()
            }

            if viewModel.type == .playlist {
                ForEach(viewModel.visibleCollectionRows) { row in
                    collectionRow(for: row)
                }
            } else {
                ForEach(viewModel.collections) { collection in
                    collectionRow(for: collection)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.reload()
        }
    }

    @ViewBuilder
    private func collectionRow(for row: SongsCollectionTreeRow) -> some View {
        HStack(spacing: 8) {
            NavigationLink {
                QueriedSongsListViewContainer(songsList: row.node.songsList())
            } label: {
                if row.hasChildren {
                    Button {
                        withAnimation {
                            viewModel.toggleExpansion(of: row.id)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(
                        row.isExpanded
                            ? "Collapse \(row.node.collection.name)"
                            : "Expand \(row.node.collection.name)"
                    ).rotationEffect(.degrees(row.isExpanded ? 90 : 0))
                }
                SongsCollectionItemView(
                    title: row.node.collection.name,
                    secondaryText: secondaryText(for: row.node),
                    systemImage: row.node.collection.isFolder ? "folder" : nil,
                    showLoading: false
                )
            }
            .padding(.leading, CGFloat(row.depth) * 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
        }
    }

    private func secondaryText(for node: SongsCollectionTreeNode) -> String? {
        guard node.hasChildren else { return nil }
        let count = node.playableCollections.count
        return count == 1 ? "1 playlist" : "\(count) playlists"
    }

    private func collectionRow(for collection: SongsCollection) -> some View {
        NavigationLink {
            QueriedSongsListViewContainer(songsList: collection.songsList())
        } label: {
            HStack {
                SongsCollectionItemView(
                    title: collection.name,
                    showLoading: false
                )
            }.lineLimit(1)
        }
    }
}

struct SongsCollectionsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SongsCollectionsListView(
                    type: .playlist,
                    title: "Playlists",
                    viewModel: SongsCollectionsListViewModel(
                        type: .playlist,
                        loader: SongsCollectionsPreviewLoader(collections: previewPlaylists)
                    )
                )
            }
            .previewDisplayName("Playlists")

            NavigationView {
                SongsCollectionsListView(
                    type: .album,
                    title: "Albums",
                    viewModel: SongsCollectionsListViewModel(
                        type: .album,
                        loader: SongsCollectionsPreviewLoader(collections: previewAlbums)
                    )
                )
            }
            .previewDisplayName("Albums")
        }
    }

    private static let previewPlaylists = [
        SongsCollection(
            name: "DJ Sets", id: "folder-dj-sets", type: .playlist, items: nil,
            isFolder: true),
        SongsCollection(
            name: "Warm Up", id: "playlist-warm-up", type: .playlist, items: [],
            parentID: "folder-dj-sets"),
        SongsCollection(
            name: "Peak Time", id: "playlist-peak-time", type: .playlist, items: [],
            parentID: "folder-dj-sets"),
        SongsCollection(
            name: "Archived Mixes", id: "folder-archive", type: .playlist, items: nil,
            isFolder: true),
        SongsCollection(
            name: "2026 Favorites", id: "playlist-favorites", type: .playlist,
            items: []),
    ]

    private static let previewAlbums = [
        SongsCollection(
            name: "City Lights After Midnight", id: "album-city-lights", type: .album,
            items: []),
        SongsCollection(name: "Small Room", id: "album-small-room", type: .album, items: []),
        SongsCollection(name: "Long Walk Home", id: "album-long-walk", type: .album, items: []),
    ]
}

private struct SongsCollectionsPreviewLoader: SongsCollectionsLoading {
    let collections: [SongsCollection]

    func loadCollections(of type: CollectionTypes) async -> [SongsCollection] {
        collections
    }
}
