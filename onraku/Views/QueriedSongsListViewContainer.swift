//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

extension MyMPMediaPropertyPredicate: Identifiable {
    var id: String {
        return (value as! String) + String(forProperty.hashValue) + String(comparisonType.hashValue)
    }
}

enum SongsSortKey: String, Equatable, CaseIterable {
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

private func getTertiaryInfo(of item: MPMediaItem, withHint: SongsSortKey) -> String? {
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

struct QueriedSongsListViewContainer: View {
    @StateObject private var vm = ViewModel()

    var filterPredicate: MyMPMediaPropertyPredicate?
    var title: String?

    var songs: [MPMediaItem] = []
    var needsInitialization: Bool = false

    var computedTitle: String {
        if let title = title {
            return title
        } else if let s = filterPredicate?.value as? String {
            return s
        } else {
            return ""
        }
    }

    var body: some View {
        Group {
            List {
                if vm.loadState == .loading {
                    ProgressView()
                }

                if !vm.searchHints.isEmpty {
                    Section {
                        ForEach(vm.searchHints) { searchHint in
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
                    ForEach(vm.sortedSongs) { song in
                        NavigationLink {
                            SongDetailView(song: song)
                        } label: {
                            SongListItemView(
                                title: song.title,
                                secondaryText: song.artist,
                                tertiaryText: getTertiaryInfo(of: song, withHint: vm.sort),
                                artwork: song.artwork
                            ).contextMenu {
                                PlayableContentMenuView(target: [song])
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(computedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Exact Match", isOn: $vm.isExactMatch).onChange(of: vm.isExactMatch)
                        { _ in Task { await vm.execQuery() } }
                    } label: {
                        Image(
                            systemName: vm.isExactMatch
                                ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    }
                    Menu {
                        PlayableContentMenuView(target: vm.sortedSongs)
                        Menu {
                            Picker("sort by", selection: $vm.sort) {
                                ForEach(SongsSortKey.allCases, id: \.self) { value in
                                    Text(value.rawValue).tag(value)
                                }
                            }
                        } label: {
                            Label(
                                "Sort Order: \(vm.sort.rawValue)",
                                systemImage: "arrow.up.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }.refreshable {
            await vm.execQuery()
        }.task {
            vm.setProps(
                songs: songs, needsInitialization: needsInitialization,
                filterPredicate: filterPredicate)

            await vm.initializeIfNeeded()
        }
    }
}

extension QueriedSongsListViewContainer {
    class ViewModel: ObservableObject {
        @Published private(set) var songs: [MPMediaItem] = []
        private var filterPredicate: MyMPMediaPropertyPredicate?
        @Published var isExactMatch: Bool = true
        @Published var loadState: LoadingState = .initial
        @Published var sort: SongsSortKey = .none

        private var isPropsSet = false

        func setProps(
            songs: [MPMediaItem], needsInitialization: Bool,
            filterPredicate: MyMPMediaPropertyPredicate?
        ) {
            if self.isPropsSet { return }

            self.isPropsSet = true
            self.songs = songs
            self.loadState = needsInitialization ? .initial : .loaded

            if let filterPredicate = filterPredicate {
                self.filterPredicate = filterPredicate
                self.isExactMatch = filterPredicate.comparisonType == .equalTo
            }
        }

        var computedPredicate: MyMPMediaPropertyPredicate? {
            if let filterPredicate = filterPredicate {
                return MyMPMediaPropertyPredicate(
                    value: filterPredicate.value,
                    forProperty: filterPredicate.forProperty,
                    comparisonType: isExactMatch ? .equalTo : .contains
                )
            }
            return nil
        }

        func initializeIfNeeded() async {
            if songs.isEmpty || loadState == .initial {
                await execQuery()
            }
        }

        func execQuery() async {
            if let computedPredicate = computedPredicate {
                let predicate = await MainActor.run { () -> MyMPMediaPropertyPredicate in
                    loadState = .loading
                    return computedPredicate
                }
                let gotSongs = await getSongsByPredicate(predicate: predicate)
                await MainActor.run {
                    songs = gotSongs
                    loadState = .loaded
                }
            }
        }

        var sortedSongs: [MPMediaItem] {
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

        var searchHints: [MyMPMediaPropertyPredicate] {
            if let filterPredicate = filterPredicate {
                switch filterPredicate.forProperty {
                case MPMediaItemPropertyGenre:
                    if let filterVal = filterPredicate.value as? String {
                        let splittedFilterVal = filterVal.intelligentlySplitIntoSubGenres()
                        if splittedFilterVal.count > 1 {
                            return splittedFilterVal.map {
                                MyMPMediaPropertyPredicate(
                                    value: $0,
                                    forProperty: filterPredicate.forProperty,
                                    comparisonType: .contains
                                )
                            }
                        }
                    }
                case MPMediaItemPropertyArtist, MPMediaItemPropertyComposer:
                    if let filterVal = filterPredicate.value as? String {
                        let splittedFilterVal = filterVal.intelligentlySplitIntoSubArtists()
                        if splittedFilterVal.count > 1 {
                            return splittedFilterVal.map {
                                MyMPMediaPropertyPredicate(
                                    value: $0,
                                    forProperty: filterPredicate.forProperty,
                                    comparisonType: .contains
                                )
                            }
                        }
                    }
                default:
                    return []
                }
            }

            return []
        }
    }
}

//struct QueriedSongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        QueriedSongsListViewContainer()
//    }
//}
