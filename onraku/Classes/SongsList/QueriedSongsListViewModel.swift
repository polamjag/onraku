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
  @Published private(set) var searchCriteria: [MyMPMediaPropertyPredicate]

  let title: String

  private let loader: () async -> [MPMediaItem]
  private let searchCriteriaLoader: ([MyMPMediaPropertyPredicate]) async -> [MPMediaItem]
  private let originalSearchCriteria: [MyMPMediaPropertyPredicate]
  private var usesEditedSearchCriteria = false
  private var sortTask: Task<Void, Never>?
  private var loadGeneration = 0
  private var sortGeneration = 0

  init(songsList: SongsList) {
    self.title = songsList.title
    self.searchCriteria = songsList.searchCriteria
    self.loader = songsList.loadSongs
    self.searchCriteriaLoader = getSongsByPredicates
    self.originalSearchCriteria = songsList.searchCriteria
  }

  init(
    title: String,
    searchCriteria: [MyMPMediaPropertyPredicate] = [],
    loader: @escaping () async -> [MPMediaItem],
    searchCriteriaLoader:
      @escaping ([MyMPMediaPropertyPredicate]) async
      -> [MPMediaItem] = getSongsByPredicates
  ) {
    self.title = title
    self.searchCriteria = searchCriteria
    self.loader = loader
    self.searchCriteriaLoader = searchCriteriaLoader
    self.originalSearchCriteria = searchCriteria
  }

  var shouldShowSearchCriteria: Bool {
    !searchCriteria.isEmpty || !originalSearchCriteria.isEmpty
  }

  var canRestoreSearchCriteria: Bool {
    searchCriteria != originalSearchCriteria
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
    loadGeneration += 1
    let generation = loadGeneration
    self.loadingState = loadingState
    let loadedSongs: [MPMediaItem]
    if usesEditedSearchCriteria {
      loadedSongs = await searchCriteriaLoader(searchCriteria)
    } else {
      loadedSongs = await loader()
    }

    guard !Task.isCancelled, generation == loadGeneration else { return }
    songs = loadedSongs
    await applySortOrder()

    guard !Task.isCancelled, generation == loadGeneration else { return }
    self.loadingState = .loaded
  }

  func removeSearchCriteria(atOffsets offsets: IndexSet) async {
    guard !offsets.isEmpty else { return }
    searchCriteria.remove(atOffsets: offsets)
    await reloadWithEditedSearchCriteria()
  }

  func removeSearchCriterion(_ predicate: MyMPMediaPropertyPredicate) async {
    guard let index = searchCriteria.firstIndex(of: predicate) else { return }
    searchCriteria.remove(at: index)
    await reloadWithEditedSearchCriteria()
  }

  func updateSearchCriterion(
    _ original: MyMPMediaPropertyPredicate,
    with updated: MyMPMediaPropertyPredicate
  ) async {
    guard let index = searchCriteria.firstIndex(of: original) else { return }
    guard searchCriteria[index] != updated else { return }
    searchCriteria[index] = updated
    await reloadWithEditedSearchCriteria()
  }

  func restoreSearchCriteria() async {
    guard canRestoreSearchCriteria else { return }
    searchCriteria = originalSearchCriteria
    await reloadWithEditedSearchCriteria()
  }

  private func reloadWithEditedSearchCriteria() async {
    usesEditedSearchCriteria = true
    await load(as: .loading)
  }

  func setSortOrder(_ newSortOrder: SongsSortKey) {
    guard sortOrder != newSortOrder else { return }
    sortOrder = newSortOrder

    sortTask?.cancel()
    sortGeneration += 1
    let generation = sortGeneration
    sortTask = Task { @MainActor [weak self] in
      guard let self else { return }
      let sortedSongs = await sortSongs(songs: self.songs, by: self.sortOrder)
      guard !Task.isCancelled, generation == self.sortGeneration else { return }
      self.displayedSongs = sortedSongs
    }
  }

  func tertiaryInfo(for song: MPMediaItem) -> String? {
    sortOrder.tertiaryInfo(for: song)
  }

  private func applySortOrder() async {
    sortGeneration += 1
    let generation = sortGeneration
    let sortedSongs = await sortSongs(songs: songs, by: sortOrder)
    guard !Task.isCancelled, generation == sortGeneration else { return }
    displayedSongs = sortedSongs
  }
}
