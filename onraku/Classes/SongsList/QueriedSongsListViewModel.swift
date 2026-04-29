//
//  QueriedSongsListViewModel.swift
//  onraku
//
//  Created by Codex on 2026/04/23.
//

import MediaPlayer
import SwiftUI

@MainActor
final class QueriedSongsListViewModel: ObservableObject {
  @Published private(set) var songs: [MPMediaItem] = []
  @Published private(set) var displayedSongs: [MPMediaItem] = []
  @Published private(set) var loadingState: LoadingState = .initial
  @Published private(set) var sortOrder: SongsSortKey = .none

  let title: String
  let searchCriteria: [MyMPMediaPropertyPredicate]

  private let loader: () async -> [MPMediaItem]
  private var sortTask: Task<Void, Never>?

  init(songsList: SongsList) {
    self.title = songsList.title
    self.searchCriteria = songsList.searchCriteria
    self.loader = songsList.loadSongs
  }

  init(
    title: String,
    searchCriteria: [MyMPMediaPropertyPredicate] = [],
    loader: @escaping () async -> [MPMediaItem]
  ) {
    self.title = title
    self.searchCriteria = searchCriteria
    self.loader = loader
  }

  var shouldShowSearchCriteria: Bool {
    searchCriteria.count > 1
  }

  deinit {
    sortTask?.cancel()
  }

  func loadIfNeeded() async {
    guard loadingState == .initial else { return }
    await load(as: .loading)
  }

  func reload() async {
    await load(as: .loadingByPullToRefresh)
  }

  private func load(as loadingState: LoadingState) async {
    self.loadingState = loadingState
    songs = await loader()
    await applySortOrder()
    self.loadingState = .loaded
  }

  func setSortOrder(_ newSortOrder: SongsSortKey) {
    guard sortOrder != newSortOrder else { return }
    sortOrder = newSortOrder

    sortTask?.cancel()
    sortTask = Task { [weak self] in
      guard let self else { return }
      await self.applySortOrder()
    }
  }

  func tertiaryInfo(for song: MPMediaItem) -> String? {
    sortOrder.tertiaryInfo(for: song)
  }

  private func applySortOrder() async {
    displayedSongs = await sortSongs(songs: songs, by: sortOrder)
  }
}
