//
//  SongMetaSearchLink.swift
//  onraku
//
//  Created by Codex on 2026/04/29.
//

import MediaPlayer

struct SongMetaSearchLink: Identifiable, Equatable {
  enum Kind: String {
    case artist
    case album
    case albumArtist
    case composer
    case userGrouping
    case genre
  }

  let kind: Kind
  let value: String?
  let predicate: MyMPMediaPropertyPredicate
  let title: String?

  var id: String {
    kind.rawValue
  }

  var isEnabled: Bool {
    !(value?.isEmpty ?? true)
  }

  static func links(for song: SongDetailLike) -> [SongMetaSearchLink] {
    [
      artist(for: song),
      album(for: song),
      albumArtist(for: song),
      composer(for: song),
      userGrouping(for: song),
      genre(for: song),
    ]
  }

  static func link(for kind: Kind, song: SongDetailLike) -> SongMetaSearchLink {
    switch kind {
    case .artist:
      return artist(for: song)
    case .album:
      return album(for: song)
    case .albumArtist:
      return albumArtist(for: song)
    case .composer:
      return composer(for: song)
    case .userGrouping:
      return userGrouping(for: song)
    case .genre:
      return genre(for: song)
    }
  }

  static func artist(for song: SongDetailLike) -> SongMetaSearchLink {
    SongMetaSearchLink(
      kind: .artist,
      value: song.artist,
      predicate: MyMPMediaPropertyPredicate(
        value: song.artist,
        forProperty: MPMediaItemPropertyArtist
      ),
      title: nil
    )
  }

  static func album(for song: SongDetailLike) -> SongMetaSearchLink {
    let predicate: MyMPMediaPropertyPredicate
    if let mediaItem = song as? MPMediaItem {
      predicate = MyMPMediaPropertyPredicate(
        value: mediaItem.albumPersistentID,
        forProperty: MPMediaItemPropertyAlbumPersistentID
      )
    } else {
      predicate = MyMPMediaPropertyPredicate(
        value: song.albumTitle,
        forProperty: MPMediaItemPropertyAlbumTitle
      )
    }

    return SongMetaSearchLink(
      kind: .album,
      value: song.albumTitle,
      predicate: predicate,
      title: song.albumTitle
    )
  }

  static func albumArtist(for song: SongDetailLike) -> SongMetaSearchLink {
    SongMetaSearchLink(
      kind: .albumArtist,
      value: song.albumArtist,
      predicate: MyMPMediaPropertyPredicate(
        value: song.albumArtist,
        forProperty: MPMediaItemPropertyAlbumArtist
      ),
      title: nil
    )
  }

  static func composer(for song: SongDetailLike) -> SongMetaSearchLink {
    SongMetaSearchLink(
      kind: .composer,
      value: song.composer,
      predicate: MyMPMediaPropertyPredicate(
        value: song.composer,
        forProperty: MPMediaItemPropertyComposer
      ),
      title: nil
    )
  }

  static func userGrouping(for song: SongDetailLike) -> SongMetaSearchLink {
    SongMetaSearchLink(
      kind: .userGrouping,
      value: song.userGrouping,
      predicate: MyMPMediaPropertyPredicate(
        value: song.userGrouping,
        forProperty: MPMediaItemPropertyUserGrouping
      ),
      title: nil
    )
  }

  static func genre(for song: SongDetailLike) -> SongMetaSearchLink {
    SongMetaSearchLink(
      kind: .genre,
      value: song.genre,
      predicate: MyMPMediaPropertyPredicate(
        value: song.genre,
        forProperty: MPMediaItemPropertyGenre
      ),
      title: nil
    )
  }
}
