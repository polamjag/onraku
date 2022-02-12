//
//  QueriedSongsListViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import SwiftUI
import MediaPlayer

struct QueriedSongsListViewContainer: View {
    @State private var songs: [MPMediaItem] = []
    @State private var loadState: LoadingState = .initial
    @State private var isExactMatch = true
    
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
    
    var computedPredicate: MyMPMediaPropertyPredicate {
        return MyMPMediaPropertyPredicate(
            value: filterPredicate.value,
            forProperty: filterPredicate.forProperty,
            comparisonType: isExactMatch ? .equalTo : .contains
        )
    }
    
    func update() async {
        loadState = .loading
        songs = await getSongsByPredicate(predicate: computedPredicate)
        loadState = .loaded
    }
    
    var body: some View {
        Group {
            if (loadState != .loaded) {
                ProgressView()
            }
            SongsListView(songs: songs, title: computedTitle, additionalMenuItems: {
                Menu {
                    Toggle("Exact Match", isOn: $isExactMatch).onChange(of: isExactMatch) { _ in Task { await update() } }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            })
        }        
        .task {
            await update()
        }
    }
}

//struct QueriedSongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        QueriedSongsListViewContainer()
//    }
//}
