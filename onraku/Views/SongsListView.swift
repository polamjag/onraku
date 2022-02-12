//
//  SongsListView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import SwiftUI
import MediaPlayer

extension MPMediaItem: Identifiable {
    func id() -> String {
        return String(self.persistentID)
    }
}

let artworkSize: CGFloat = 42

struct SongsListView: View {
    var songs: [MPMediaItem]
    var title: String
    
    var body: some View {
        List {
            Section(footer: Text("\(songs.count) songs")) {
                ForEach(songs) { song in
                    SongListItemView(song: song).onTapGesture {
                        playMediaItems(items: [song])
                    }
                }
            }
        }.navigationTitle(title).toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    PlayableContentMenuView(target: songs)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct SongsListView_Previews: PreviewProvider {
    static var previews: some View {
        SongsListView(songs: [], title: "Some Playlist")
    }
}
