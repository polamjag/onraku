//
//  NowPlayingViewContainer.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct NowPlayingViewContainer: View {
  @Environment(\.scenePhase) private var scenePhase

  @MainActor @State var nowPlayingItem: MPMediaItem?
  @MainActor @State var loadingState: LoadingState = .initial

  @MainActor @State var isAppearing = false

  @MainActor func refreshNowPlayingSong() async {
    await MainActor.run {
      loadingState = .loading
      nowPlayingItem = getNowPlayingSong()
      loadingState = .loaded
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
    }
    .task {
      await refreshNowPlayingSong()
    }
    .refreshable {
      await refreshNowPlayingSong()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: .musicPlayerNowPlayingItemDidChange),
      perform: { _ in
        Task { if isAppearing { await refreshNowPlayingSong() } }
      }
    )
    .onChange(of: scenePhase) { _, newPhase in
      guard newPhase == .active else { return }
      Task { await refreshNowPlayingSong() }
    }
    .onAppear {
      isAppearing = true
    }
    .onDisappear {
      isAppearing = false
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
