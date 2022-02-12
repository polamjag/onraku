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

let artworkSize: CGFloat = 48

func playMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    MPMusicPlayerController.systemMusicPlayer.setQueue(with: collection)
    MPMusicPlayerController.systemMusicPlayer.play()
}
func enqueueMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
    MPMusicPlayerController.systemMusicPlayer.append(qd)
    MPMusicPlayerController.systemMusicPlayer.play()
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
            Section {
                ForEach(getSongs()) { song in
                    HStack {
                        Image(
                            uiImage:
                                song.item.artwork!.image(at: CGSize(width: artworkSize, height: artworkSize))!
                        ).resizable().frame(width: artworkSize, height: artworkSize).cornerRadius(4)
                        VStack(alignment: .leading) {
                            Text(song.item.title ?? "").lineLimit(1)
                            Text(song.item.artist ?? "").font(.footnote).foregroundColor(.secondary).lineLimit(1)
                        }
                    }.onTapGesture {
                        playMediaItems(items: [song.item])
                    }
                }
            }
        }.navigationTitle(title).toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        playMediaItems(items: songs)
                    }) {
                        Label("Play All", systemImage: "play")
                    }
                    Button(action: {
                        enqueueMediaItems(items: songs)
                    }) {
                        Label("Delete", systemImage: "plus")
                    }
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
