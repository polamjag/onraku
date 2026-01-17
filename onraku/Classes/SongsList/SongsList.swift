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

struct SongsListFromPlaylist: SongsList {
  let playlist: MPMediaPlaylist
  
  var title: String {
    self.playlist.name ?? ""
  }
  
  func songs() -> [MPMediaItem] {
    []
  }
  
  var shouldShowSearchCriteria: Bool { false }
  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
//    [playlist]
    []
  }
}

struct SongsListFromPredicates : SongsList {
  let predicates: [MyMPMediaPropertyPredicate]
  
  var title: String {
    "Search Result"
  }
  
  func songs() -> [MPMediaItem] {
    []
  }
  
  var shouldShowSearchCriteria: Bool {
    predicates.count > 1
  }
  
  func searchCriteria() -> [MyMPMediaPropertyPredicate]? {
    predicates
  }
}

func predicateToSongsList(_ predicate: MyMPMediaPropertyPredicate) -> SongsList {
  return SongsListFixed(fixedSongs: [], title: "")
}
