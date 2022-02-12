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

struct SongsListViewContainer: View {
    @State var playlists: [Playlist] = []
    @State var loadState: LoadingState = .initial
    @State var lastLoadedNavigationDestinationType: NavigationDestinationType?
    var type: NavigationDestinationType
    
    var body: some View {
        List {
            if (loadState == .loading) {
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
        }.task {
            if (loadState != .loaded || lastLoadedNavigationDestinationType != type) {
                loadState = .loading
                playlists = await loadPlaylistsForType(type: type)
                loadState = .loaded
            }
        }
            
    }
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
