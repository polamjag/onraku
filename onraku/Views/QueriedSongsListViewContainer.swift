//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

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
                                PlayableItemsMenuView(target: .one(song))
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
                    }.disabled(!vm.isExactMatchConfigurable)

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
                await vm.performRefresh()
            }.task {
                await vm.setProps(songs: songs, filterPredicate: filterPredicate)
                await vm.initializeIfNeeded()
            }
    }
}

struct FilterPredicateConfiguration {
    var filterPredicate: MyMPMediaPropertyPredicate
    var isExactMatch: Bool

    func load() async -> [MPMediaItem] {
        return []
    }
}

extension QueriedSongsListViewContainer {
    class ViewModel: ObservableObject {
        @Published private(set) var songs: [MPMediaItem] = []
        @Published @MainActor var loadState: LoadingState = .initial

        private var filterPredicateConfig: FilterPredicateConfiguration?

        @MainActor var isExactMatchConfigurable: Bool {
            self.filterPredicateConfig != nil
        }
        
        @Published @MainActor var isExactMatch: Bool = true {
            didSet {
                if self.isPropsSet {
                    Task {
                        await execQuery()
                    }
                }
            }
        }

        @Published @MainActor var sort: SongsSortKey = .none {
            didSet {
                Task {
                    await MainActor.run { self.loadState = .loading }
                    await setSortedSongs()
                    await MainActor.run { self.loadState = .loaded }
                }
            }
        }

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

            await MainActor.run {
                self.loadState = .loading
                let needsInitialization = filterPredicate != nil && songs.isEmpty

                self.loadState = needsInitialization ? .initial : .loaded

                self.songs = songs
                self.enumeratedSortedSongs = Array(songs.enumerated())

                if let filterPredicate {
                    self.filterPredicateConfig = FilterPredicateConfiguration(
                        filterPredicate: filterPredicate,
                        isExactMatch: filterPredicate.comparisonType == .equalTo
                    )
                }

                self.isPropsSet = true
            }
        }

        @MainActor var computedPredicate: MyMPMediaPropertyPredicate? {
            if let config = filterPredicateConfig {
                return MyMPMediaPropertyPredicate(
                    value: config.filterPredicate.value,
                    forProperty: config.filterPredicate.forProperty,
                    comparisonType: config.isExactMatch ? .equalTo : .contains
                )
            }
            return nil
        }

        @MainActor func initializeIfNeeded() async {
            if songs.isEmpty || loadState == .initial {
                await execQuery()
            }
        }

        func performRefresh() async {
            return await query(loadingState: .loadingByPullToRefresh)
        }

        func execQuery() async {
            return await query(loadingState: .loading)
        }

        @MainActor private func query(loadingState: LoadingState) async {
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

        private func setSortedSongs() async {
            let sorting = await MainActor.run { () -> SongsSortKey in return self.sort }
            let sortedSongs = Array((await sortSongs(songs: songs, by: sorting)).enumerated())

            await MainActor.run {
                self.enumeratedSortedSongs = sortedSongs
            }
        }

        var searchHints: [MyMPMediaPropertyPredicate] {
            if let filterPredicateConfig {
                return filterPredicateConfig.filterPredicate.getNextSearchHints()
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
