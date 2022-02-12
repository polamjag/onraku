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
func appendMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
    MPMusicPlayerController.systemMusicPlayer.append(qd)
    MPMusicPlayerController.systemMusicPlayer.play()
}
func prependMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
    MPMusicPlayerController.systemMusicPlayer.prepend(qd)
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
            Section(footer: Text("\(songs.count) songs")) {
                ForEach(getSongs()) { song in
                    SongListItemView(song: song.item).onTapGesture {
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
                        Label("Play All Now", systemImage: "play")
                    }
                    Divider()
                    Button(action: {
                        prependMediaItems(items: songs)
                    }) {
                        Label("Prepend All to Queue", systemImage: "arrow.uturn.right")
                    }
                    Button(action: {
                        appendMediaItems(items: songs)
                    }) {
                        Label("Append All to Queue", systemImage: "arrow.turn.down.right")
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
