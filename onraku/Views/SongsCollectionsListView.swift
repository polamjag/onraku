//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

enum LoadingState {
    case initial, loading, loaded, loadingByPullToRefresh
}

struct SongsCollectionsListView: View {
    @State @MainActor var playlists: [SongsCollection] = []
    @State var loadState: LoadingState = .initial

    var type: CollectionType
    var title: String

    func loadPlaylists() async {
        await MainActor.run {
            loadState = .loading
        }
        let gotPlaylists = await loadSongsCollectionsOf(type)
        await MainActor.run {
            playlists = gotPlaylists
            loadState = .loaded
        }

    }

    var body: some View {
        Group {
            if loadState == .loading {
                ProgressView()
            }
            List(playlists) { playlist in
                NavigationLink {
                    QueriedSongsListViewContainer(
                        filterPredicate: playlist.getFilterPredicate(),
                        songs: playlist.items
                    )
                } label: {
                    HStack {
                        SongsCollectionItemView(
                            title: playlist.name,
                            itemsCount: playlist.items.count)
                    }.lineLimit(1).contextMenu {
                        PlayableItemsMenuView(
                            target: playlist.items)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)

        }.task {
            if playlists.isEmpty {
                await loadPlaylists()
            }
        }.refreshable {
            await loadPlaylists()
        }
    }
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
