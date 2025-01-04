//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer
import RegexBuilder

func loadSongsCollectionsOf(_ type: CollectionType) async -> [SongsCollection] {
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

private func loadAllCollectionsOf(_ type: CollectionType) -> [SongsCollection] {
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

private func loadAllUserGroupings() -> [SongsCollection] {
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

func getSongsByPredicate(predicate: MyMPMediaPropertyPredicate) async
  -> [MPMediaItem]
{
  let task = Task.detached(priority: .high) { () -> [MPMediaItem] in
    if predicate.forProperty == MPMediaItemPropertyUserGrouping {
      if let s = predicate.value as? String {
        return getSongsByUserGrouping(
          userGrouping: s, comparisonType: predicate.comparisonType)
      } else {
        return []
      }
    } else {
      let items =
        MPMediaQuery(
          filterPredicates: Set([
            MPMediaPropertyPredicate(
              value: predicate.value,
              forProperty: predicate.forProperty,
              comparisonType: predicate.comparisonType)
          ])
        ).items ?? []

      if items.isEmpty {
        return []
      }

      if let stringPredicateValue = predicate.value as? String {
        let regex = Regex {
          /\b/
          stringPredicateValue
          /\b/
        }

        return
          items
          .filter {
            if let val = $0.value(forProperty: predicate.forProperty) as? String
            {
              let matches = val.matches(of: regex)
              return !matches.isEmpty
            } else {
              return true
            }
          }
      } else {
        return items
      }

    }
  }

  return await task.result.get().filter { $0.mediaType == MPMediaType.music }
}

private func getSongsByUserGrouping(
  userGrouping: String, comparisonType: MPMediaPredicateComparison
)
  -> [MPMediaItem]
{
  let songs = MPMediaQuery.songs().items ?? []

  switch comparisonType {
  case .equalTo:
    return songs.filter { ($0.userGrouping ?? "") == userGrouping }
  case .contains:
    return songs.filter { $0.userGrouping?.contains(userGrouping) ?? false }
  @unknown default:
    return songs.filter { $0.userGrouping?.contains(userGrouping) ?? false }
  }

}

func getNowPlayingSong() -> MPMediaItem? {
  return MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
}
