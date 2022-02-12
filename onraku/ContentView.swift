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

private struct Playlist: Identifiable {
    let name: String
    let id: String
    let navigationDestinationInfo: NavigationDestinationInfo
}

struct ContentView: View {
    @State private var playlists: [Playlist] = []
    
    func loadPlaylist() {
        let playlistsQuery = MPMediaQuery.playlists().collections ?? []
        playlists = playlistsQuery.map {
            Playlist(
                name: $0.value(forProperty: MPMediaPlaylistPropertyName)! as! String,
                id: String($0.representativeItem?.persistentID ?? 0),
                navigationDestinationInfo: NavigationDestinationInfo(
                    type: .playlist, songs: $0.items
                )
            )
        }
    }
    
    func loadGroupings() {
        let songs = MPMediaQuery.songs().items
        let songsByGrouping = songs?.reduce([String:[MPMediaItem]](), {
            var prev = $0
            let gr = $1.userGrouping ?? "__no__grouping__"
            prev[gr] = (prev[gr] ?? []) + [$1]
            return prev
        })
        if (songsByGrouping == nil) { return }
        playlists = songsByGrouping!.keys.sorted().map {
            return Playlist(
                name: $0,
                id: $0,
                navigationDestinationInfo: NavigationDestinationInfo(
                    type: .userGrouping,
                    songs: songsByGrouping?[$0] ?? []
                )
            )
        }
    }
    
    var body: some View {
        List {
            Section {
                Button("Load Playlists") {
                    loadPlaylist()
                }
                Button("Load Groupings") {
                    loadGroupings()
                }
            }
            
            Section {
                ForEach(playlists) { playlist in
                    NavigationLink {
                        SongsListView(songs: playlist.navigationDestinationInfo.songs, title: playlist.name)
                    } label: {
                        HStack {
                            SongListIGroupItemView(title: playlist.name, itemsCount: playlist.navigationDestinationInfo.songs.count)
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
