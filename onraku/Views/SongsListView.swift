//
//  SongsListView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI

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
    case bpm = "BPM"
    case playCountDesc = "Most Played"
    case playCountAsc = "Least Played"
}

private func getTertiaryInfo(of item: MPMediaItem, withHint: SortSongsBy) -> String? {
    switch withHint {
    case .none, .title, .artist:
        return nil
    case .album:
        return item.albumTitle ?? "-"
    case .genre:
        return item.genre ?? "-"
    case .userGrouping:
        return item.userGrouping ?? "-"
    case .addedAt:
        return item.dateAdded.formatted(date: .abbreviated, time: .omitted)
    case .bpm:
        return item.beatsPerMinute == 0 ? "-" : String(item.beatsPerMinute)
    case .playCountAsc, .playCountDesc:
        return String(item.playCount)
    }
}

struct SongsListView<Content: View>: View {
    var songs: [MPMediaItem]
    var title: String
    var isLoading: Bool
    @State var sort: SortSongsBy = .none

    let additionalMenuItems: Content
    let searchHints: [MyMPMediaPropertyPredicate]

    init(
        songs: [MPMediaItem], title: String, isLoading: Bool,
        searchHints: [MyMPMediaPropertyPredicate], @ViewBuilder additionalMenuItems: () -> Content
    ) {
        self.songs = songs
        self.title = title
        self.searchHints = searchHints
        self.isLoading = isLoading
        self.additionalMenuItems = additionalMenuItems()
    }

    private var sortedSongs: [MPMediaItem] {
        switch sort {
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
        case .bpm:
            return songs.sorted {
                ($0.beatsPerMinute == 0 ? Int.max : $0.beatsPerMinute)
                    < ($1.beatsPerMinute == 0 ? Int.max : $1.beatsPerMinute)
            }
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
            if isLoading {
                ProgressView()
            }

            if !searchHints.isEmpty {
                Section {
                    ForEach(searchHints) { searchHint in
                        NavigationLink {
                            QueriedSongsListViewContainer(
                                filterPredicate: searchHint
                            )
                        } label: {
                            Text(searchHint.value as! String)
                        }
                    }
                } header: {
                    Text("Search")
                }
            }

            Section(footer: Text("\(songs.count) songs")) {
                ForEach(sortedSongs) { song in
                    NavigationLink {
                        SongDetailView(song: song)
                    } label: {
                        SongListItemView(
                            title: song.title,
                            secondaryText: song.artist,
                            tertiaryText: getTertiaryInfo(of: song, withHint: sort),
                            artwork: song.artwork
                        ).contextMenu {
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
                    Menu {
                        Picker("sort by", selection: $sort) {
                            ForEach(SortSongsBy.allCases, id: \.self) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                    } label: {
                        Label("Sort Order: \(sort.rawValue)", systemImage: "arrow.up.arrow.down")
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
        SongsListView(
            songs: [], title: "Some Playlist", isLoading: false, searchHints: [],
            additionalMenuItems: {})
    }
}
