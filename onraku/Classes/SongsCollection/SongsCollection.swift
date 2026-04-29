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
    SongsListFromPredicates(predicates: [filterPredicate], customTitle: name)
  }
}
