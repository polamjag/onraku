//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

enum LoadingState {
    case initial, loading, loaded
}

struct SongAssortmentsView: View {
    @State var playlists: [Playlist] = []
    @State var loadState: LoadingState = .initial

    var type: NavigationDestinationType
    var title: String
    
    func loadPlaylists() async {
        loadState = .loading
        playlists = await loadPlaylistsForType(type: type)
        loadState = .loaded
    }
    
    var body: some View {
        Group {
            if (loadState == .loading) {
                ProgressView()
            } else {
                List(playlists) { playlist in
                    NavigationLink {
                        SongsListView(songs: playlist.navigationDestinationInfo.songs, title: playlist.name, searchHints: [], additionalMenuItems: {})
                    } label: {
                        HStack {
                            SongAssortmentItemView(title: playlist.name, itemsCount: playlist.navigationDestinationInfo.songs.count)
                        }.lineLimit(1).contextMenu{
                            PlayableContentMenuView(target: playlist.navigationDestinationInfo.songs)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(title)
            }
        }
        .task {
            if (playlists.isEmpty) {
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
