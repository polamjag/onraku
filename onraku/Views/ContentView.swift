//
//  ContentView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI

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
    @State private var activeTab: String?
    var body: some View {
        TabView {
            NavigationView {
                List {
                    NavigationLink {
                        SongAssortmentsView(type: .playlist, title: "Playlists")
                    } label: {
                        Text("Playlists")
                    }

                    NavigationLink {
                        SongAssortmentsView(type: .userGrouping, title: "User Groupings")
                    } label: {
                        Text("User Groupings")
                    }
                }.navigationTitle("Library")
            }.tabItem {
                Image(systemName: "music.quarternote.3")
                Text("Library")
            }

            NavigationView {
                NowPlayingViewContainer().navigationBarTitleDisplayMode(.inline)
            }.tabItem {
                Image(systemName: "play")
                Text("Now Playing")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
