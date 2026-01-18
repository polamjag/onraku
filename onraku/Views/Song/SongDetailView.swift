//
//  SongDetailView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct SongDetailView: View {
  var song: SongDetailLike
  var title: String?

  @StateObject private var digDeeperItems = DiggingViewModel()
  @StateObject private var digDeepestItems = DiggingViewModel()

  @StateObject private var playlistsOfSong = PlaylistsBySongViewModel()

  var body: some View {
    List {
      SongMetaView(song: song)

      Section {
        NavigationLink {
          QueriedSongsListViewContainer(
            songsList: SongsListFixed(fixedSongs: digDeeperItems.songs, title: "Dig Deeper"),
          )
        } label: {
          SongsCollectionItemView(
            title: "Dig Deeper", systemImage: "square.2.layers.3d",
            itemsCount: digDeeperItems.songs.count,
            showLoading: digDeeperItems.loadingState.isLoading)
        }

        NavigationLink {
          QueriedSongsListViewContainer(
            songsList: SongsListFixed(fixedSongs: digDeepestItems.songs, title: "Dig Deepest"),
          )
        } label: {
          SongsCollectionItemView(
            title: "Dig Deepest", systemImage: "square.3.layers.3d",
            itemsCount: digDeepestItems.songs.count,
            showLoading: digDeepestItems.loadingState.isLoading)
        }
      }

      Section("Show in Playlist") {
        playlistsView()
      }
    }.navigationTitle(title ?? song.title ?? "Song Detail").toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Menu {
          PlayableItemsMenuView(target: .array([song as! MPMediaItem]))
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }.task {
      _ = await (digDeeperItems.load(for: song as! MPMediaItem, withDepth: 1), digDeepestItems.load(for: song as! MPMediaItem, withDepth: 2), playlistsOfSong.load(for: song as! MPMediaItem))
    }.id(song.refreshingIdentifier)
  }

  private func playlistsView() -> some View {
    Group {
      if playlistsOfSong.loadingState.isLoading {
        AnyView(
          HStack(alignment: .center) {
            Spacer()
            ProgressView()
            Spacer()
          }
        )
      } else {
        if playlistsOfSong.playlists.isEmpty {
          AnyView(
            Text("no playlists").foregroundStyle(.secondary)
          )
        } else {
          AnyView(
            ForEach(playlistsOfSong.playlists) { playlist in
              NavigationLink {
                QueriedSongsListViewContainer(
                  title: playlist.name, songs: playlist.items ?? []
                )
              } label: {
                SongsCollectionItemView(
                  title: playlist.name
                )
              }
            }
          )
        }
      }
    }
  }
}

@MainActor
final class PlaylistsBySongViewModel: ObservableObject {
  private var currentSong: MPMediaItem?
  @Published private(set) var playlists: [SongsCollection] = []
  @Published private(set) var loadingState: LoadingState = .initial
  private var loadTask: Task<Void, Never>?

  func load(for song: MPMediaItem) async {
    guard song != currentSong else { return }
    loadingState = .loading
    currentSong = song

    loadTask?.cancel()
    let requestedSong = song

    loadTask = Task { [weak self] in
      let res = await getPlaylistsBySong(requestedSong)
      guard let self, !Task.isCancelled, requestedSong == self.currentSong else { return }
      await MainActor.run {
        self.playlists = res
        self.loadingState = .loaded
      }
    }

    await loadTask?.value
  }
}

@MainActor
final class DiggingViewModel: ObservableObject {
  private var currentSong: MPMediaItem?
  @Published private(set) var songs: [MPMediaItem] = []
  @Published private(set) var predicates: [MyMPMediaPropertyPredicate] = []
  @Published private(set) var loadingState: LoadingState = .initial
  private var loadTask: Task<Void, Never>?

  func load(for song: MPMediaItem, withDepth linkDepth: Int) async {
    guard song != currentSong else { return }
    loadingState = .loading
    currentSong = song

    loadTask?.cancel()
    let requestedSong = song

    loadTask = Task { [weak self] in
      let res = await getDiggedItems(of: requestedSong, includeGenre: false, withDepth: linkDepth)
      guard let self, !Task.isCancelled, requestedSong == self.currentSong else { return }
      await MainActor.run {
        self.songs = res.items
        self.predicates = res.predicates
        self.loadingState = .loaded
      }
    }

    await loadTask?.value
  }
}

