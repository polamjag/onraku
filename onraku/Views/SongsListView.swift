//
//  SongsListView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import SwiftUI
import MediaPlayer

extension MPMediaItem: Identifiable {
    public var id: String {
        return String(self.persistentID)
    }
}

extension MyMPMediaPropertyPredicate: Identifiable {
    var id: String {
        return (value as! String) + String(forProperty.hashValue) + String(comparisonType.hashValue)
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

struct SongsListView<Content: View>: View {
    var songs: [MPMediaItem]
    var title: String
    @State var sort: SortSongsBy = .none
    
    let additionalMenuItems: Content
    let searchHints: [MyMPMediaPropertyPredicate]
    
    init(songs: [MPMediaItem], title: String, searchHints: [MyMPMediaPropertyPredicate], @ViewBuilder additionalMenuItems: () -> Content) {
        self.songs = songs
        self.title = title
        self.searchHints = searchHints
        self.additionalMenuItems = additionalMenuItems()
    }

    private var sortedSongs: [MPMediaItem] {
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
            if (!searchHints.isEmpty) {
                Section{
                    ForEach(searchHints) { searchHint in
                        NavigationLink {
                            QueriedSongsListViewContainer(
                                filterPredicate: searchHint
                            )
                        } label: {
                            Text(searchHint.value as! String)
                        }
                    }
                } header: { Text("Search") }
            }
            Section(footer: Text("\(songs.count) songs")) {
                ForEach(sortedSongs) { song in
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
                self.additionalMenuItems
                Menu {
                    PlayableContentMenuView(target: sortedSongs)
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
        SongsListView(songs: [], title: "Some Playlist", searchHints: [], additionalMenuItems: {})
    }
}
