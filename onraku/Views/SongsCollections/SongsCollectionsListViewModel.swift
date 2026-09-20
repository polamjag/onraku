//
//  SongsCollectionsListViewModel.swift
//  onraku
//
//  Created by Codex on 2026/04/23.
//

import SwiftUI

@MainActor
protocol SongsCollectionsLoading {
  func loadCollections(of type: CollectionTypes) async -> [SongsCollection]
}

struct MediaLibrarySongsCollectionsLoader: SongsCollectionsLoading {
  func loadCollections(of type: CollectionTypes) async -> [SongsCollection] {
    await loadSongsCollectionsOf(type)
  }
}

struct SongsCollectionTreeRow: Identifiable, Hashable {
  let node: SongsCollectionTreeNode
  let depth: Int
  let isExpanded: Bool

  var id: String {
    node.id
  }

  var hasChildren: Bool {
    node.hasChildren
  }
}

@MainActor
final class SongsCollectionsListViewModel: ObservableObject {
  @Published private(set) var collections: [SongsCollection] = []
  @Published private(set) var loadState: LoadingState = .initial
  @Published private(set) var expandedCollectionIDs: Set<String> = []

  var collectionTree: [SongsCollectionTreeNode] {
    buildSongsCollectionTree(from: collections)
  }

  var visibleCollectionRows: [SongsCollectionTreeRow] {
    visibleRows(from: collectionTree, depth: 0)
  }

  let type: CollectionTypes

  private let loader: SongsCollectionsLoading
  private var loadGeneration = 0
  private var loadTask: Task<[SongsCollection], Never>?

  init(type: CollectionTypes) {
    self.type = type
    self.loader = MediaLibrarySongsCollectionsLoader()
  }

  init(type: CollectionTypes, loader: SongsCollectionsLoading) {
    self.type = type
    self.loader = loader
  }

  deinit {
    loadTask?.cancel()
  }

  func loadIfNeeded() async {
    guard loadState == .initial else { return }
    await load()
  }

  func reload() async {
    await load()
  }

  func toggleExpansion(of nodeID: String) {
    if expandedCollectionIDs.contains(nodeID) {
      expandedCollectionIDs.remove(nodeID)
    } else {
      expandedCollectionIDs.insert(nodeID)
    }
  }

  private func load() async {
    loadGeneration += 1
    let generation = loadGeneration
    loadState = .loading
    loadTask?.cancel()
    let loader = loader
    let type = type
    let task = Task { await loader.loadCollections(of: type) }
    loadTask = task
    let loadedCollections = await task.value
    guard !Task.isCancelled, generation == loadGeneration else { return }
    collections = loadedCollections
    expandedCollectionIDs.formIntersection(expandableCollectionIDs)
    loadState = .loaded
  }

  private var expandableCollectionIDs: Set<String> {
    Set(collectionTree.flatMap(\.expandableIDs))
  }

  private func visibleRows(
    from nodes: [SongsCollectionTreeNode],
    depth: Int
  ) -> [SongsCollectionTreeRow] {
    nodes.flatMap { node -> [SongsCollectionTreeRow] in
      let isExpanded = expandedCollectionIDs.contains(node.id)
      let row = SongsCollectionTreeRow(
        node: node,
        depth: depth,
        isExpanded: isExpanded
      )

      guard isExpanded, let children = node.children else {
        return [row]
      }

      return [row] + visibleRows(from: children, depth: depth + 1)
    }
  }
}
