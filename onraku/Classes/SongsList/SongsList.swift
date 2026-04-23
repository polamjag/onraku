//
//  SongsList.swift
//  onraku
//
//  Created by Satoru Abe on 2026/01/10.
//

import MediaPlayer

protocol SongsList {
  func songs() -> [MPMediaItem]
  var title: String { get }
  
  var shouldShowSearchCriteria: Bool { get }
  func searchCriteria() -> [MyMPMediaPropertyPredicate]?
}

struct SongsListFixed: SongsList {
  let fixedSongs: [MPMediaItem]
  let title: String
  
  func songs() -> [MPMediaItem] {
    self.fixedSongs
  }
  var shouldShowSearchCriteria: Bool { false }
  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
    nil
  }
}

struct SongsListLoaded: SongsList {
  let loadedSongs: [MPMediaItem]
  let title: String
  let predicates: [MyMPMediaPropertyPredicate]

  func songs() -> [MPMediaItem] {
    loadedSongs
  }

  var shouldShowSearchCriteria: Bool {
    predicates.count > 1
  }

  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
    predicates.isEmpty ? nil : predicates
  }
}

struct SongsListFromPlaylist: SongsList {
  let playlist: MPMediaPlaylist
  
  var title: String {
    self.playlist.name ?? ""
  }
  
  func songs() -> [MPMediaItem] {
    playlist.items
  }
  
  var shouldShowSearchCriteria: Bool { false }
  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
//    [playlist]
    []
  }
}

struct SongsListFromPredicates : SongsList {
  let predicates: [MyMPMediaPropertyPredicate]
  var customTitle: String?
  
  var title: String {
    customTitle ?? "Search Result"
  }
  
  func songs() -> [MPMediaItem] {
    predicates
      .flatMap { getSongsByPredicateNow(predicate: $0) }
      .unique()
  }
  
  var shouldShowSearchCriteria: Bool {
    predicates.count > 1
  }
  
  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
    predicates
  }
}

func predicateToSongsList(_ predicate: MyMPMediaPropertyPredicate) -> SongsList {
  SongsListFromPredicates(
    predicates: [predicate],
    customTitle: predicate.value as? String
  )
}
