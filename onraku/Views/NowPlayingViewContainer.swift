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

    @StateObject private var viewModel: NowPlayingViewModel

    @MainActor
    init(viewModel: NowPlayingViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? NowPlayingViewModel())
    }

    var body: some View {
        Group {
            if let nowPlayingItem = viewModel.nowPlayingItem {
                SongDetailView(song: nowPlayingItem, title: "Now Playing")
            } else if viewModel.loadingState == .loading {
                ProgressView()
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
        NavigationView {
            NowPlayingViewContainer(
                viewModel: NowPlayingViewModel(nowPlayingLoader: PreviewNowPlayingLoader())
            )
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Not Playing")

        NotPlayingView()
            .previewDisplayName("Empty State")
    }
}

private struct PreviewNowPlayingLoader: NowPlayingLoading {
    func loadNowPlayingSong() async -> MPMediaItem? {
        nil
    }
}
