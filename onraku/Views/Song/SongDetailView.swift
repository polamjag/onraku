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

  @StateObject private var digDeeperItems: DiggingViewModel
  @StateObject private var digDeepestItems: DiggingViewModel

  @StateObject private var playlistsOfSong: PlaylistsBySongViewModel

  @MainActor
  init(
    song: SongDetailLike,
    title: String? = nil,
    digDeeperItems: DiggingViewModel? = nil,
    digDeepestItems: DiggingViewModel? = nil,
    playlistsOfSong: PlaylistsBySongViewModel? = nil
  ) {
    self.song = song
    self.title = title
    _digDeeperItems = StateObject(
      wrappedValue: digDeeperItems ?? DiggingViewModel()
    )
    _digDeepestItems = StateObject(
      wrappedValue: digDeepestItems ?? DiggingViewModel()
    )
    _playlistsOfSong = StateObject(
      wrappedValue: playlistsOfSong ?? PlaylistsBySongViewModel()
    )
  }

  private var mediaItem: MPMediaItem? {
    song as? MPMediaItem
  }

  var body: some View {
    List {
      SongMetaView(song: song)

      if mediaItem != nil {
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
          }.disabled(digDeeperItems.loadingState.isLoading || digDeeperItems.songs.isEmpty)

          NavigationLink {
            QueriedSongsListViewContainer(
              songsList: SongsListFixed(fixedSongs: digDeepestItems.songs, title: "Dig Deepest"),
            )
          } label: {
            SongsCollectionItemView(
              title: "Dig Deepest", systemImage: "square.3.layers.3d",
              itemsCount: digDeepestItems.songs.count,
              showLoading: digDeepestItems.loadingState.isLoading)
          }.disabled(digDeepestItems.loadingState.isLoading || digDeepestItems.songs.isEmpty)
        }

        Section("Show in Playlist") {
          playlistsView()
        }
      }
    }.navigationTitle(title ?? song.title ?? "Song Detail").toolbar {
      if let mediaItem {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Menu {
            PlayableItemsMenuView(target: .array([mediaItem]))
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    }.task(id: mediaItem?.refreshingIdentifier ?? song.refreshingIdentifier) {
      _ = await (
        digDeeperItems.load(for: song, withDepth: 1),
        digDeepestItems.load(for: song, withDepth: 2),
        playlistsOfSong.load(for: song)
      )
    }
  }

  @ViewBuilder
  private func playlistsView() -> some View {
    if playlistsOfSong.loadingState.isLoading {
      HStack(alignment: .center) {
        Spacer()
        ProgressView()
        Spacer()
      }
    } else if playlistsOfSong.playlists.isEmpty {
      Text("no playlists").foregroundStyle(.secondary)
    } else {
      ForEach(playlistsOfSong.playlists) { playlist in
        NavigationLink {
          QueriedSongsListViewContainer(
            songsList: SongsListLoaded(
              loadedSongs: playlist.items ?? [],
              title: playlist.name,
              predicates: []
            )
          )
        } label: {
          SongsCollectionItemView(
            title: playlist.name
          )
        }
      }
    }
  }
}
