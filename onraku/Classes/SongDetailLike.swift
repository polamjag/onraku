//
//  SongDetailLike.swift
//  onraku
//
//  Created by Satoru Abe on 2025/05/06.
//

import MediaPlayer

protocol SongDetailLike {
  var albumArtist: String? { get }
  var albumTitle: String? { get }
  var albumTrackCount: Int { get }
  var albumTrackNumber: Int { get }
  var artist: String? { get }
  var artwork: MPMediaItemArtwork? { get }
  var beatsPerMinute: Int { get }
  var comments: String? { get }
  var isCompilation: Bool { get }
  var composer: String? { get }
  var dateAdded: Date { get }
  var discCount: Int { get }
  var discNumber: Int { get }
  var genre: String? { get }
  var lastPlayedDate: Date? { get }
  var lyrics: String? { get }
  var playCount: Int { get }
  var rating: Int { get }
  var releaseDate: Date? { get }
  var releaseYear: Int? { get }
  var skipCount: Int { get }
  var title: String? { get }
  var userGrouping: String? { get }
  var playbackDuration: TimeInterval { get }
}

struct DummySongDetail: SongDetailLike {
  var albumArtist: String?
  var albumTitle: String?
  var albumTrackCount: Int
  var albumTrackNumber: Int
  var artist: String?
  var artwork: MPMediaItemArtwork?
  var beatsPerMinute: Int
  var comments: String?
  var isCompilation: Bool
  var composer: String?
  var dateAdded: Date
  var discCount: Int
  var discNumber: Int
  var genre: String?
  var lastPlayedDate: Date?
  var lyrics: String?
  var playCount: Int
  var rating: Int
  var releaseDate: Date?
  var releaseYear: Int?
  var skipCount: Int
  var title: String?
  var userGrouping: String?
  var playbackDuration: TimeInterval
}

extension MPMediaItem: SongDetailLike {}
