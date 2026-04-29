//
//  SongDetailViewModels.swift
//  onraku
//
//  Created by Codex on 2026/04/23.
//

import MediaPlayer
import SwiftUI

struct DiggingLoadResult {
  let songs: [MPMediaItem]
  let predicates: [MyMPMediaPropertyPredicate]
}

protocol DiggingLoading {
  func loadDiggingItems(for song: SongDetailLike, withDepth depth: Int) async
    -> DiggingLoadResult
}

protocol SongPlaylistLoading {
  func loadPlaylists(for song: SongDetailLike) async -> [SongsCollection]
}

struct MediaItemDiggingLoader: DiggingLoading {
  func loadDiggingItems(for song: SongDetailLike, withDepth depth: Int) async
    -> DiggingLoadResult
  {
    guard let mediaItem = song as? MPMediaItem else {
      return DiggingLoadResult(songs: [], predicates: [])
    }

    let result = await getDiggedItems(
      of: mediaItem,
      includeGenre: false,
      withDepth: depth
    )
    return DiggingLoadResult(songs: result.items, predicates: result.predicates)
  }
}

struct MediaItemSongPlaylistLoader: SongPlaylistLoading {
  func loadPlaylists(for song: SongDetailLike) async -> [SongsCollection] {
    guard let mediaItem = song as? MPMediaItem else { return [] }
    return await getPlaylistsBySong(mediaItem)
  }
}

struct SongScopedLoadTracker {
  private(set) var currentSongIdentifier: String?

  mutating func beginLoad(for song: SongDetailLike) -> String? {
    let identifier = song.refreshingIdentifier
    guard identifier != currentSongIdentifier else { return nil }
    currentSongIdentifier = identifier
    return identifier
  }

  func matchesCurrentLoad(_ identifier: String) -> Bool {
    identifier == currentSongIdentifier
  }
}

@MainActor
final class PlaylistsBySongViewModel: ObservableObject {
  @Published private(set) var playlists: [SongsCollection] = []
  @Published private(set) var loadingState: LoadingState = .initial

  private let loader: SongPlaylistLoading
  private var loadTracker = SongScopedLoadTracker()
  private var loadTask: Task<Void, Never>?

  init(loader: SongPlaylistLoading = MediaItemSongPlaylistLoader()) {
    self.loader = loader
  }

  deinit {
    loadTask?.cancel()
  }

  func load(for song: SongDetailLike) async {
    guard let requestedSongIdentifier = loadTracker.beginLoad(for: song) else {
      return
    }
    playlists = []
    loadingState = .loading

    loadTask?.cancel()
    let requestedSong = song

    loadTask = Task { [weak self] in
      let result = await self?.loader.loadPlaylists(for: requestedSong) ?? []
      guard let self, !Task.isCancelled,
        self.loadTracker.matchesCurrentLoad(requestedSongIdentifier)
      else { return }

      await MainActor.run {
        self.playlists = result
        self.loadingState = .loaded
      }
    }

    await loadTask?.value
  }
}

@MainActor
final class DiggingViewModel: ObservableObject {
  @Published private(set) var songs: [MPMediaItem] = []
  @Published private(set) var predicates: [MyMPMediaPropertyPredicate] = []
  @Published private(set) var loadingState: LoadingState = .initial

  private let loader: DiggingLoading
  private var loadTracker = SongScopedLoadTracker()
  private var loadTask: Task<Void, Never>?

  init(loader: DiggingLoading = MediaItemDiggingLoader()) {
    self.loader = loader
  }

  func songsList(title: String) -> SongsList {
    SongsListLoaded(
      loadedSongs: songs,
      title: title,
      predicates: predicates
    )
  }

  deinit {
    loadTask?.cancel()
  }

  func load(for song: SongDetailLike, withDepth linkDepth: Int) async {
    guard let requestedSongIdentifier = loadTracker.beginLoad(for: song) else {
      return
    }
    songs = []
    predicates = []
    loadingState = .loading

    loadTask?.cancel()
    let requestedSong = song

    loadTask = Task { [weak self] in
      let result = await self?.loader.loadDiggingItems(
        for: requestedSong,
        withDepth: linkDepth
      )
      guard let self, let result, !Task.isCancelled,
        self.loadTracker.matchesCurrentLoad(requestedSongIdentifier)
      else { return }

      await MainActor.run {
        self.songs = result.songs
        self.predicates = result.predicates
        self.loadingState = .loaded
      }
    }

    await loadTask?.value
  }
}
