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

enum NavigationDestinationType {
    case userGrouping, playlist
}

struct NavigationDestinationInfo {
    let type: NavigationDestinationType
    let songs: [MPMediaItem]
}

struct Playlist: Identifiable {
    let name: String
    let id: String
    let navigationDestinationInfo: NavigationDestinationInfo
}

struct SongAssortmentsView: View {
    @State @MainActor var playlists: [Playlist] = []
    @State var loadState: LoadingState = .initial

    var type: NavigationDestinationType
    var title: String

    func loadPlaylists() async {
        loadState = .loading
        let gotPlaylists = await loadPlaylistsForType(type: type)
        await MainActor.run {
            playlists = gotPlaylists
        }
        loadState = .loaded
    }

    var body: some View {
        Group {
            List(playlists) { playlist in
                NavigationLink {
                    QueriedSongsListViewContainer(
                        songs: playlist.navigationDestinationInfo.songs
                    )
                } label: {
                    HStack {
                        SongAssortmentItemView(
                            title: playlist.name,
                            itemsCount: playlist.navigationDestinationInfo.songs.count)
                    }.lineLimit(1).contextMenu {
                        PlayableContentMenuView(
                            target: playlist.navigationDestinationInfo.songs)
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
