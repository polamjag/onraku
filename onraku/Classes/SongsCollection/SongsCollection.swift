//
//  SongsCollection.swift
//  onraku
//
//  Created by Satoru Abe on 2025/01/04.
//

import MediaPlayer

enum CollectionTypes: String, Equatable, CaseIterable {
  case playlist = "Playlists"
  case album = "Albums"
  case artist = "Artists"
  case genre = "Genres"
  case userGrouping = "User Groupings"

  func getQueryForType() -> MPMediaQuery? {
    switch self {
    case .userGrouping:
      return nil
    case .playlist:
      return MPMediaQuery.playlists()
    case .genre:
      return MPMediaQuery.genres()
    case .artist:
      return MPMediaQuery.artists()
    case .album:
      return MPMediaQuery.albums()
    }
  }

  var systemImageName: String {
    switch self {
    case .playlist:
      return "list.dash"
    case .album:
      return "square.stack"
    case .genre:
      return "guitars"
    case .artist:
      return "music.mic"
    case .userGrouping:
      return "latch.2.case"
    }
  }

  var queryPredicateType: String {
    switch self {
    case .userGrouping:
      return MPMediaItemPropertyUserGrouping
    case .artist:
      return MPMediaItemPropertyArtist
    case .album:
      return MPMediaItemPropertyAlbumTitle
    case .genre:
      return MPMediaItemPropertyGenre
    case .playlist:
      return MPMediaPlaylistPropertyName
    }
  }
}

struct SongsCollection: Identifiable, Hashable {
  static func == (lhs: SongsCollection, rhs: SongsCollection) -> Bool {
    return lhs.id == rhs.id
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let name: String
  let id: String
  let type: CollectionTypes
  let items: [MPMediaItem]?
  let parentID: String?
  let isFolder: Bool

  init(
    name: String,
    id: String,
    type: CollectionTypes,
    items: [MPMediaItem]?,
    parentID: String? = nil,
    isFolder: Bool = false
  ) {
    self.name = name
    self.id = id
    self.type = type
    self.items = items
    self.parentID = parentID
    self.isFolder = isFolder
  }

  var filterPredicate: MyMPMediaPropertyPredicate {
    MyMPMediaPropertyPredicate(
      value: name,
      forProperty: type.queryPredicateType,
      comparisonType: .equalTo
    )
  }

  func getFilterPredicate() -> MyMPMediaPropertyPredicate? {
    filterPredicate
  }

  func songsList() -> SongsList {
    SongsListFromPredicates(
      predicates: [filterPredicate],
      customTitle: name,
      searchCriteria: type == .playlist ? [] : nil
    )
  }
}

struct SongsCollectionTreeNode: Identifiable, Hashable {
  let collection: SongsCollection
  let children: [SongsCollectionTreeNode]?

  var id: String {
    collection.id
  }

  var isFolder: Bool {
    collection.isFolder || children?.isEmpty == false
  }

  var hasChildren: Bool {
    children?.isEmpty == false
  }

  var playableCollections: [SongsCollection] {
    if !collection.isFolder {
      return [collection]
    }

    return children?.flatMap(\.playableCollections) ?? []
  }

  var descendantIDs: [String] {
    [id] + (children?.flatMap(\.descendantIDs) ?? [])
  }

  var expandableIDs: [String] {
    (hasChildren ? [id] : []) + (children?.flatMap(\.expandableIDs) ?? [])
  }

  func songsList() -> SongsList {
    if !collection.isFolder {
      return collection.songsList()
    }

    let collections = playableCollections
    return SongsListFromPredicates(
      predicates: collections.map(\.filterPredicate),
      customTitle: collection.name,
      searchCriteria: []
    )
  }
}

func buildSongsCollectionTree(from collections: [SongsCollection])
  -> [SongsCollectionTreeNode]
{
  let collectionIDs = Set(collections.map(\.id))
  var rootCollections: [SongsCollection] = []
  var childCollectionsByParentID: [String: [SongsCollection]] = [:]

  for collection in collections {
    if let parentID = collection.parentID, collectionIDs.contains(parentID) {
      childCollectionsByParentID[parentID, default: []].append(collection)
    } else {
      rootCollections.append(collection)
    }
  }

  func makeNode(
    from collection: SongsCollection,
    ancestors: Set<String>
  ) -> SongsCollectionTreeNode {
    let childCollections = childCollectionsByParentID[collection.id] ?? []
    let nextAncestors = ancestors.union([collection.id])
    let children =
      childCollections
      .filter { !nextAncestors.contains($0.id) }
      .map { makeNode(from: $0, ancestors: nextAncestors) }

    return SongsCollectionTreeNode(
      collection: collection,
      children: children.isEmpty ? nil : children
    )
  }

  var tree: [SongsCollectionTreeNode] = []
  var includedIDs: Set<String> = []

  for collection in rootCollections + collections where !includedIDs.contains(collection.id) {
    let node = makeNode(from: collection, ancestors: [])
    tree.append(node)
    includedIDs.formUnion(node.descendantIDs)
  }

  return tree
}
