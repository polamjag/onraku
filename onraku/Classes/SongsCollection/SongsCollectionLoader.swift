//
//  SongsCollectionLoader.swift
//  onraku
//
//  Created by Satoru Abe on 2026/01/10.
//

import MediaPlayer

func loadSongsCollectionsOf(_ type: CollectionTypes) async -> [SongsCollection] {
  let task = Task.detached(priority: .high) { () -> [SongsCollection] in
    switch type {
    case .playlist, .genre, .artist, .album:
      return loadAllCollectionsOf(type)
    case .userGrouping:
      return loadAllUserGroupings()
    }
  }

  return await task.result.get()
}

func loadAllCollectionsOf(_ type: CollectionTypes) -> [SongsCollection] {
  if let collections = type.getQueryForType()?.collections {
    return collections.map {
      SongsCollection(
        name: $0.getCollectionName(as: type) ?? "",
        id: String($0.persistentID),
        type: type,
        items: nil
      )
    }
  } else {
    return []
  }
}

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

func getPlaylistsBySong(_ song: MPMediaItem) async -> [SongsCollection] {
  let playlists = loadAllCollectionsOf(.playlist)
  
  let res = await withTaskGroup(of: Optional<SongsCollection>.self) { group in
    for playlist in playlists {
      group.addTask {
        if let predicate = playlist.getFilterPredicate() {
          let songs = await getSongsByPredicate(predicate: predicate)
          if songs.contains(song) {
            return SongsCollection(
              name: playlist.name,
              id: playlist.id,
              type: .playlist,
              items: songs
            )
          }
        }
        
        return nil
      }
    }
    
    var ret: [SongsCollection] = []
    
    for await result in group {
      if let result {
        ret.append(result)
      }
    }
    
    return ret
  }
  return res.sorted { $0.name < $1.name }
}
