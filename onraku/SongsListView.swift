//
//  SongsListView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import SwiftUI
import MediaPlayer

struct IdentifiableMediaItem: Identifiable {
    let id: String
    var item: MPMediaItem
}

struct SongsListView: View {
    var songs: [MPMediaItem]
    var title: String
    func getSongs() -> [IdentifiableMediaItem] {
        return self.songs.map {
            IdentifiableMediaItem(id: String($0.persistentID), item: $0)
        }
    }
    var body: some View {
        List {
            ForEach(getSongs()) { song in
                HStack {
                    Image(
                        uiImage:
                            song.item.artwork!.image(at: CGSize(width: 50, height: 50))!
                    ).resizable().frame(width: 50, height: 50)
                    VStack(alignment: .leading) {
                        Text(song.item.title ?? "")
                        Text(song.item.artist ?? "").font(.footnote).foregroundColor(.secondary)
                    }
                }
            }
        }.navigationTitle(title)
    }
}

struct SongsListView_Previews: PreviewProvider {
    static var previews: some View {
        SongsListView(songs: [], title: "Some Playlist")
    }
}
