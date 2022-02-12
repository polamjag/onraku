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
    
    var body: some View {
        SongsListView(songs: songs, title: "").task {
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
