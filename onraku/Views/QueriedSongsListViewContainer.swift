//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

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
            SongsListView(
                songs: vm.songs, title: computedTitle, isLoading: vm.loadState == .loading,
                searchHints: vm.searchHints,
                additionalMenuItems: {
                    Menu {
                        // does not works in first tap
                        // Toggle("Exact Match", isOn: $isExactMatch).onChange(of: isExactMatch) { _ in Task { await update() } }

                        Button(
                            vm.isExactMatch ?? false ? "Exact Match: On" : "Exact Match: Off",
                            action: {
                                Task {
                                    await MainActor.run {
                                        vm.isExactMatch = !(vm.isExactMatch ?? false)
                                    }
                                    await vm.execQuery()
                                }
                            })
                    } label: {
                        Image(
                            systemName: vm.isExactMatch ?? false
                                ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    }
                })
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
        @Published var isExactMatch: Bool?
        @Published var loadState: LoadingState = .initial

        func setProps(
            songs: [MPMediaItem], needsInitialization: Bool,
            filterPredicate: MyMPMediaPropertyPredicate?
        ) {
            self.songs = songs
            self.loadState = needsInitialization ? .initial : .loaded

            if let filterPredicate = filterPredicate {
                self.filterPredicate = filterPredicate
                self.isExactMatch = filterPredicate.comparisonType == .equalTo
            }
        }

        var computedPredicate: MyMPMediaPropertyPredicate? {
            if let filterPredicate = filterPredicate, let isExactMatch = isExactMatch {
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
