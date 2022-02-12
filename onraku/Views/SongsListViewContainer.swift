//
//  SongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI

struct SongsListViewContainer: View {
    @State var playlists: [Playlist] = []
    @State var isLoading: Bool = false
    var type: NavigationDestinationType
    
    var body: some View {
        List {
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
        }.task {
            Task {
                do {
                    isLoading = true
                    playlists = await loadPlaylistsForType(type: type)
                    isLoading = false
                }
            }
        }
    }
}

//struct SongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        SongsListViewContainer(loader: ()  -> [Playlist] {  [] })
//    }
//}
