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

  @StateObject private var viewModel = NowPlayingViewModel()

  var body: some View {
    Group {
      if viewModel.loadingState == .loading {
        ProgressView()
      } else if let nowPlayingItem = viewModel.nowPlayingItem {
        SongDetailView(song: nowPlayingItem, title: "Now Playing")
      } else {
        NotPlayingView()
      }
    }
    .task {
      await viewModel.refreshNowPlayingSong()
    }
    .refreshable {
      await viewModel.refreshNowPlayingSong()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: .musicPlayerNowPlayingItemDidChange),
      perform: { _ in
        Task { await viewModel.handleNowPlayingItemDidChange() }
      }
    )
    .onChange(of: scenePhase) { _, newPhase in
      Task { await viewModel.handleScenePhaseChange(newPhase) }
    }
    .onAppear {
      viewModel.onAppear()
    }
    .onDisappear {
      viewModel.onDisappear()
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
