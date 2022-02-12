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
    @State private var isLoading: Bool = false
    
    func loadPlaylist() {
        let dq = DispatchQueue(label: "songfinder", qos: .userInteractive)
        isLoading = true
        dq.async {
            let playlistsQuery = MPMediaQuery.playlists().collections ?? []
            let p: [Playlist] = playlistsQuery.map {
                Playlist(
                    name: $0.value(forProperty: MPMediaPlaylistPropertyName)! as! String,
                    id: String($0.representativeItem?.persistentID ?? 0),
                    navigationDestinationInfo: NavigationDestinationInfo(
                        type: .playlist, songs: $0.items
                    )
                )
            }
            
            DispatchQueue.main.async {
                isLoading = false
                playlists = p
            }
        }
    }
    
    func loadGroupings() {
        let dq = DispatchQueue(label: "songfinder", qos: .userInteractive)
        isLoading = true
        dq.async {
            let songs = MPMediaQuery.songs().items
            let songsByGrouping = songs?.reduce([String:[MPMediaItem]](), {
                var prev = $0
                let gr = $1.userGrouping ?? ""
                prev[gr] = (prev[gr] ?? []) + [$1]
                return prev
            })
            if (songsByGrouping == nil) { return }
            let p: [Playlist] = songsByGrouping!.keys.sorted().map {
                return Playlist(
                    name: $0,
                    id: $0,
                    navigationDestinationInfo: NavigationDestinationInfo(
                        type: .userGrouping,
                        songs: songsByGrouping?[$0] ?? []
                    )
                )
            }
            
            DispatchQueue.main.async {
                isLoading = false
                playlists = p
            }
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
