//
//  NowPlayingViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct NowPlayingViewContainer: View {
    @State var nowPlayingItem: MPMediaItem?
    @State var loadingState: LoadingState = .initial

    var body: some View {
        Group {
            if loadingState == .loading {
                ProgressView()
            } else if let nowPlayingItem = nowPlayingItem {
                SongDetailView(song: nowPlayingItem, title: "Now Playing")
            } else {
                NotPlayingView()
            }
        }.task {
            nowPlayingItem = getNowPlayingSong()
        }.refreshable {
            nowPlayingItem = getNowPlayingSong()
        }
    }
}
struct NotPlayingView: View {
    var body: some View {
        Text("Not Playing").foregroundColor(.secondary)
    }
}

struct NowPlayingViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingViewContainer()
    }
}
