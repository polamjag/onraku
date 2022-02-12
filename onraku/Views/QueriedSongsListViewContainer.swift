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
    
    var filterPredicate: MyMPMediaPropertyPredicate
    
    var title: String {
        if let s = filterPredicate.value as? String {
            return s
        } else {
            return ""
        }
    }
    
    var body: some View {
        Group {
            if (loadState != .loaded) {
                ProgressView()
            }
            SongsListView(songs: songs, title: title)
        }
        .task {
            loadState = .loading
            songs = await getSongsByPredicate(predicate: filterPredicate)
            loadState = .loaded
        }
    }
}

//struct QueriedSongsListViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        QueriedSongsListViewContainer()
//    }
//}
