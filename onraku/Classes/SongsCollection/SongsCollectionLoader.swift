//
//  SongsCollectionLoader.swift
//  onraku
//
//  Created by Satoru Abe on 2026/01/10.
//

import MediaPlayer

@MainActor
func loadSongsCollectionsOf(_ type: CollectionTypes) async -> [SongsCollection] {
  guard !Task.isCancelled else { return [] }
  switch type {
  case .playlist, .genre, .artist, .album:
    return loadAllCollectionsOf(type)
  case .userGrouping:
    return loadAllUserGroupings()
  }
}

@MainActor
func loadAllCollectionsOf(_ type: CollectionTypes) -> [SongsCollection] {
  if let collections = type.getQueryForType()?.collections {
    return collections.map { collection in
      let playlist = collection as? MPMediaPlaylist
      let parentID =
        playlist?.hasParent == true
        ? playlist?.parentPersistentID.map(String.init)
        : nil

      return SongsCollection(
        name: collection.getCollectionName(as: type) ?? "",
        id: String(collection.persistentID),
        type: type,
        items: nil,
        parentID: parentID,
        isFolder: playlist?.isFolder ?? false
      )
    }
  } else {
    return []
  }
}

@MainActor
func loadAllUserGroupings() -> [SongsCollection] {
  let songs = MPMediaQuery.songs().items
  let songsByGrouping = songs?.reduce(
    [String: [MPMediaItem]](),
    {
      var prev = $0
      let gr = $1.userGrouping ?? ""
      prev[gr] = (prev[gr] ?? []) + [$1]
      return prev
    })
  if songsByGrouping == nil { return [] }
  return songsByGrouping!.keys.sorted().map {
    return SongsCollection(
      name: $0,
      id: $0,
      type: .userGrouping,
      items: songsByGrouping?[$0] ?? []
    )
  }
}

@MainActor
func getPlaylistsBySong(_ song: MPMediaItem) async -> [SongsCollection] {
  let playlists = loadAllCollectionsOf(.playlist)

  var result: [SongsCollection] = []
  for playlist in playlists {
    guard !Task.isCancelled, !playlist.isFolder else { continue }

    if let predicate = playlist.getFilterPredicate() {
      let songs = await getSongsByPredicate(predicate: predicate)
      if songs.contains(song) {
        result.append(
          SongsCollection(
            name: playlist.name,
            id: playlist.id,
            type: .playlist,
            items: songs,
            parentID: playlist.parentID,
            isFolder: playlist.isFolder
          )
        )
      }
    }
  }

  return result.sorted { $0.name < $1.name }
}
