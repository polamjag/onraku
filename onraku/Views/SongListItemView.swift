//
//  SongListItemView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI
import MediaPlayer

protocol SongLike {
    var title: String? { get }
    var artist: String? { get }
    var artwork: MPMediaItemArtwork? { get }
}

extension MPMediaItem: SongLike {}

class DummySong: SongLike {
    var title: String?
    var artist: String?
    var artwork: MPMediaItemArtwork?
    
    init(title: String, artist: String) {
        self.title = title
        self.artist = artist
        self.artwork = MPMediaItemArtwork.init(boundsSize: CGSize(width: 48, height: 48), requestHandler: { _ in UIImage.checkmark })
    }
}

struct SongListItemView: View {
    var song: SongLike
    
    var body: some View {
        HStack {
            Image(
                uiImage:
                    song.artwork!.image(at: CGSize(width: artworkSize, height: artworkSize))!
            ).resizable().frame(width: artworkSize, height: artworkSize).cornerRadius(4)
            VStack(alignment: .leading) {
                Text(song.title ?? "").lineLimit(1)
                Text(song.artist ?? "").font(.footnote).foregroundColor(.secondary).lineLimit(1)
            }
        }
    }
}

struct SongListItemView_Previews: PreviewProvider {
    static var previews: some View {
        SongListItemView(song: DummySong(title: "Super song 超いい曲", artist: "Lolem ipsum"))
    }
}
