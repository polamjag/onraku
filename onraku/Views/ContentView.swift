//
//  ContentView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import SwiftUI
import MediaPlayer

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

struct ContentView: View {
    @State private var playlists: [Playlist] = []
    @State private var isLoading: Bool = false
    
    func withAsyncPlaylistsLoader(loader: (@escaping () async -> [Playlist])) {
        Task {
            do {
                isLoading = true
                playlists = await loader()
                isLoading = false
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                Button("Load Playlists") {
                    withAsyncPlaylistsLoader(loader: loadPlaylist)
                }
                Button("Load Groupings") {
                    withAsyncPlaylistsLoader(loader: loadGroupings)
                }
            }
            
            Section {
                if (isLoading) {
                    ProgressView()
                } else {
                    ForEach(playlists) { playlist in
                        NavigationLink {
                            SongsListView(songs: playlist.navigationDestinationInfo.songs, title: playlist.name)
                        } label: {
                            HStack {
                                SongGroupItemView(title: playlist.name, itemsCount: playlist.navigationDestinationInfo.songs.count)
                            }.lineLimit(1).contextMenu{
                                PlayableContentMenuView(target: playlist.navigationDestinationInfo.songs)
                            }
                        }
                    }
                }
            }
        }.navigationTitle("onraku")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
