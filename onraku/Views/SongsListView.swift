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

enum SortSongsBy: String, Equatable, CaseIterable {
    case none = "Default"
    case title = "Title"
    case album = "Album"
    case artist = "Artist"
    case genre = "Genre"
    case userGrouping = "User Grouping"
    case addedAt = "Date Added"
    case playCountDesc = "Most Played"
    case playCountAsc = "Least Played"
}

struct SongsListView: View {
    var songs: [MPMediaItem]
    var title: String
    @State var sort: SortSongsBy = .none
    
    func getSortedSongs() -> [MPMediaItem] {
        switch (sort) {
        case .addedAt:
            return songs.sorted { $0.dateAdded < $1.dateAdded }
        case .title:
            return songs.sorted { $0.title ?? "" < $1.title ?? "" }
        case .album:
            return songs.sorted { $0.albumTitle ?? "" < $1.albumTitle ?? "" }
        case .artist:
            return songs.sorted { $0.artist ?? "" < $1.artist ?? "" }
        case .genre:
            return songs.sorted { $0.genre ?? "" < $1.genre ?? "" }
        case .userGrouping:
            return songs.sorted { $0.userGrouping ?? "" < $1.userGrouping ?? "" }
        case .playCountAsc:
            return songs.sorted { $0.playCount < $1.playCount }
        case .playCountDesc:
            return songs.sorted { $0.playCount > $1.playCount }
        default:
            return songs
        }
    }
    
    var body: some View {
        List {
            Section(footer: Text("\(songs.count) songs")) {
                ForEach(getSortedSongs()) { song in
                    NavigationLink {
                        SongDetailView(song: song)
                    } label: {
                        SongListItemView(song: song).contextMenu {
                            PlayableContentMenuView(target: [song])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    PlayableContentMenuView(target: songs)
                    Picker("sort by", selection: $sort) {
                        ForEach(SortSongsBy.allCases, id: \.self) { value in
                            Text(value.rawValue).tag(value)
                        }
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
