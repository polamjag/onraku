//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI
import MediaPlayer

struct QueriedSongsListViewContainer: View {
    @State @MainActor private var songs: [MPMediaItem] = []
    @State @MainActor private var loadState: LoadingState = .initial
    @State @MainActor private var isExactMatch = true
    
    var filterPredicate: MyMPMediaPropertyPredicate
    var title: String?
    
    var computedTitle: String {
        if let title = title {
            return title
        } else if let s = filterPredicate.value as? String {
            return s
        } else {
            return ""
        }
    }
    
    @MainActor var computedPredicate: MyMPMediaPropertyPredicate {
        return MyMPMediaPropertyPredicate(
            value: filterPredicate.value,
            forProperty: filterPredicate.forProperty,
            comparisonType: isExactMatch ? .equalTo : .contains
        )
    }
    
    func update() async {
        await MainActor.run {
            loadState = .loading
        }
        let predicate = await MainActor.run { () -> MyMPMediaPropertyPredicate in
            return computedPredicate
        }
        let gotSongs = await getSongsByPredicate(predicate: predicate)
        await MainActor.run {
            songs = gotSongs
            loadState = .loaded
        }
    }
    
    var searchHints: [MyMPMediaPropertyPredicate] {
        switch (filterPredicate.forProperty) {
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
        case MPMediaItemPropertyArtist:
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
        return []
    }
    
    var body: some View {
        Group {
            if (loadState != .loaded) {
                ProgressView()
            }
            SongsListView(songs: songs, title: computedTitle, searchHints: searchHints, additionalMenuItems: {
                Menu {
                    // does not works in first tap
                    // Toggle("Exact Match", isOn: $isExactMatch).onChange(of: isExactMatch) { _ in Task { await update() } }
                    
                    Button(isExactMatch ? "Exact Match: On" : "Exact Match: Off", action: {
                        Task {
                            await MainActor.run {
                                isExactMatch = !isExactMatch
                            }
                            await update()
                        }
                    })
                } label: {
                    Image(systemName: isExactMatch ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                }
            })
        }.refreshable {
            await update()
        }.task {
            await MainActor.run {
                isExactMatch = filterPredicate.comparisonType == .equalTo
            }
            if (songs.isEmpty || loadState == .initial) {
                await update()
            }
        }
    }
}

//struct QueriedSongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        QueriedSongsListViewContainer()
//    }
//}
