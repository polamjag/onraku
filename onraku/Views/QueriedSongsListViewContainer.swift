//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

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

struct SearchHintItemView: View {
    var searchHint: MyMPMediaPropertyPredicate
    @State var resultCount: Int?
    var shouldBeDisabled: Bool {
        if let resultCount = resultCount {
            return resultCount == 0
        } else {
            return false
        }
    }

    var body: some View {
        if !shouldBeDisabled {
            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: searchHint
                )
            } label: {
                SongsCollectionItemView(
                    title: searchHint.someFriendlyLabel,
                    systemImage: "magnifyingglass",
                    itemsCount: resultCount
                )
            }.disabled(shouldBeDisabled).task {
                let res = await getSongsByPredicate(predicate: searchHint)
                resultCount = res.count
            }
        }
    }
}

struct QueriedSongsListViewContainer: View {
    @StateObject private var vm = ViewModel()

    var filterPredicate: MyMPMediaPropertyPredicate?
    var title: String?

    var songs: [MPMediaItem] = []

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
        List {
            if !vm.searchHints.isEmpty {
                Section {
                    ForEach(vm.searchHints) { searchHint in
                        SearchHintItemView(searchHint: searchHint)
                    }
                }
            }

            if vm.shouldShowLoadingIndicator {
                LoadingCellView()
            } else {
                Section(footer: Text("\(vm.songs.count) songs")) {
                    ForEach(vm.enumeratedSortedSongs, id: \.element) { index, song in
                        NavigationLink {
                            SongDetailView(song: song)
                        } label: {
                            SongItemView(
                                title: song.title,
                                secondaryText: song.artist,
                                tertiaryText: getTertiaryInfo(of: song, withHint: vm.sort),
                                artwork: song.artwork
                            ).contextMenu {
                                PlayableItemsMenuView(target: .array([song]))
                                if vm.songs.count > 2 {
                                    Divider()
                                    PlayableItemsAboveAndBelowMenuView(
                                        target: vm.enumeratedSortedSongs, currentIndex: index)
                                }
                            }
                        }
                    }
                }
            }
        }.navigationTitle(computedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("Filter with Exact Match", isOn: $vm.isExactMatch)
                    } label: {
                        Image(
                            systemName: vm.isExactMatch
                                ? "magnifyingglass.circle.fill"
                                : "magnifyingglass.circle")
                    }.disabled(!vm.exactMatchSettable)

                    Menu {
                        PlayableItemsMenuView(target: .enumSeq(vm.enumeratedSortedSongs))
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
            }.refreshable {
                await vm.refreshQuery()
            }.task {
                await vm.setProps(songs: songs, filterPredicate: filterPredicate)
                await vm.initializeIfNeeded()
            }
    }
}

extension QueriedSongsListViewContainer {
    class ViewModel: ObservableObject {
        @Published private(set) var songs: [MPMediaItem] = []
        private var filterPredicate: MyMPMediaPropertyPredicate?
        @Published @MainActor var isExactMatch: Bool = true {
            didSet {
                if self.isPropsSet {
                    Task {
                        await execQuery()
                    }
                }
            }
        }

        @MainActor var exactMatchSettable: Bool {
            return filterPredicate != nil
        }

        @Published @MainActor var sort: SongsSortKey = .none {
            didSet {
                Task { await setSortedSongs() }
            }
        }

        @Published @MainActor var loadState: LoadingState = .initial
        @MainActor var shouldShowLoadingIndicator: Bool {
            return loadState == .loading
        }

        @Published @MainActor var enumeratedSortedSongs:
            [EnumeratedSequence<[MPMediaItem]>.Element] = []

        private var isPropsSet = false

        func setProps(
            songs: [MPMediaItem],
            filterPredicate: MyMPMediaPropertyPredicate?
        ) async {
            if self.isPropsSet { return }

            self.songs = songs

            let needsInitialization = filterPredicate != nil && songs.isEmpty

            await MainActor.run {
                self.enumeratedSortedSongs = Array(songs.enumerated())
                self.loadState = needsInitialization ? .initial : .loaded

                if let filterPredicate = filterPredicate {
                    self.filterPredicate = filterPredicate
                    self.isExactMatch = filterPredicate.comparisonType == .equalTo
                }

                self.isPropsSet = true
            }
        }

        @MainActor var computedPredicate: MyMPMediaPropertyPredicate? {
            if let filterPredicate = filterPredicate {
                return MyMPMediaPropertyPredicate(
                    value: filterPredicate.value,
                    forProperty: filterPredicate.forProperty,
                    comparisonType: isExactMatch ? .equalTo : .contains
                )
            }
            return nil
        }

        @MainActor func initializeIfNeeded() async {
            if songs.isEmpty || loadState == .initial {
                await execQuery()
            }
        }

        func refreshQuery() async {
            return await query(loadingState: .loadingByPullToRefresh)
        }

        func execQuery() async {
            return await query(loadingState: .loading)
        }

        @MainActor func query(loadingState: LoadingState) async {
            if let computedPredicate = computedPredicate {
                let predicate = await MainActor.run { () -> MyMPMediaPropertyPredicate in
                    loadState = loadingState
                    return computedPredicate
                }
                let gotSongs = await getSongsByPredicate(predicate: predicate)
                await MainActor.run {
                    songs = gotSongs
                    loadState = .loaded
                }
                await setSortedSongs()
            }
        }

        func setSortedSongs() async {
            let sorting = await MainActor.run { () -> SongsSortKey in return self.sort }
            let task = Task.detached(priority: .high) { [self] () -> [MPMediaItem] in
                switch sorting {
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
                        $0.beatsPerMinuteForSorting
                            < $1.beatsPerMinuteForSorting
                    }
                case .playCountAsc:
                    return songs.sorted { $0.playCount < $1.playCount }
                case .playCountDesc:
                    return songs.sorted { $0.playCount > $1.playCount }
                default:
                    return songs
                }
            }

            do {
                let sortedSongs = try await Array(task.result.get().enumerated())
                await MainActor.run {
                    self.enumeratedSortedSongs = sortedSongs
                }
            } catch {

            }
        }

        var searchHints: [MyMPMediaPropertyPredicate] {
            if let filterPredicate = filterPredicate {
                return filterPredicate.getNextSearchHints()
            } else {
                return []
            }
        }
    }
}

struct QueriedSongsListViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        QueriedSongsListViewContainer()
    }
}
