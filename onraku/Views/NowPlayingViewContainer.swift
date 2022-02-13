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

    @MainActor func refreshNowPlayingSong() async {
        await MainActor.run {
            nowPlayingItem = getNowPlayingSong()
        }
    }

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
            await refreshNowPlayingSong()
        }.onReceive(
            // https://dishware.sakura.ne.jp/swift/archives/484
            NotificationCenter.default.publisher(
                for: Notification.Name("MPMusicPlayerControllerNowPlayingItemDidChangeNotification")
            ),
            perform: { _ in
                Task { await refreshNowPlayingSong() }
            }
        )
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
