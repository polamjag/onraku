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

    var body: some View {
        List {
            NavigationLink {
                SongsListViewContainer(type: .playlist)
            } label: {
                Text("Playlists")
            }
            
            NavigationLink {
                SongsListViewContainer(type: .userGrouping)
            } label: {
                Text("User Groupings")
            }
        }.navigationTitle("onraku")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
