//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer
import RegexBuilder

enum CollectionType: String, Equatable, CaseIterable {
  case playlist = "Playlist"
  case album = "Album"
  case artist = "Artist"
  case genre = "Genre"
  case userGrouping = "User Grouping"

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
      return "rectangle.3.group"
    }
  }

  var queryPredicateType: String? {
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
  let type: CollectionType
  let items: [MPMediaItem]?

  func getFilterPredicate() -> MyMPMediaPropertyPredicate? {
    if let forProperty = type.queryPredicateType {
      return MyMPMediaPropertyPredicate(
        value: name,
        forProperty: forProperty,
        comparisonType: .equalTo
      )
    }
    return nil
  }
}

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

      let regex = Regex {
        /\b/
        predicate.value as! String
        /\b/
      }

      return
        items
        .filter {
          let val = $0.value(forProperty: predicate.forProperty) as! String

          let matches = val.matches(of: regex)
          return !matches.isEmpty
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
