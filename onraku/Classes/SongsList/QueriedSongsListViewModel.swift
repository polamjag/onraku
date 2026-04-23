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
  @Published private(set) var loadingState: LoadingState = .initial

  let title: String
  let searchCriteria: [MyMPMediaPropertyPredicate]

  private let loader: () async -> [MPMediaItem]

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
    self.loadingState = .loaded
  }
}
