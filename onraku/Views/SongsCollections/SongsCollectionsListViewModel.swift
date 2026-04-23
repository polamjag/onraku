//
//  SongsCollectionsListViewModel.swift
//  onraku
//
//  Created by Codex on 2026/04/23.
//

import SwiftUI

protocol SongsCollectionsLoading {
  func loadCollections(of type: CollectionTypes) async -> [SongsCollection]
}

struct MediaLibrarySongsCollectionsLoader: SongsCollectionsLoading {
  func loadCollections(of type: CollectionTypes) async -> [SongsCollection] {
    await loadSongsCollectionsOf(type)
  }
}

@MainActor
final class SongsCollectionsListViewModel: ObservableObject {
  @Published private(set) var collections: [SongsCollection] = []
  @Published private(set) var loadState: LoadingState = .initial

  let type: CollectionTypes

  private let loader: SongsCollectionsLoading

  init(
    type: CollectionTypes,
    loader: SongsCollectionsLoading = MediaLibrarySongsCollectionsLoader()
  ) {
    self.type = type
    self.loader = loader
  }

  func loadIfNeeded() async {
    guard collections.isEmpty else { return }
    await load()
  }

  func reload() async {
    await load()
  }

  private func load() async {
    loadState = .loading
    collections = await loader.loadCollections(of: type)
    loadState = .loaded
  }
}
