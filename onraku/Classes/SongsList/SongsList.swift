//
//  SongsList.swift
//  onraku
//
//  Created by Satoru Abe on 2026/01/10.
//

import MediaPlayer

protocol SongsList {
  func songs() -> [MPMediaItem]
  var shouldShowSearchCriteria: Bool { get }
  var canConfigureExactMatch: Bool { get }
}

struct SongsListFromPlaylist: SongsList {
  let playlist: MPMediaPlaylist
  
  func songs() -> [MPMediaItem] {
    []
  }
  
  var shouldShowSearchCriteria: Bool {
    false
  }
  
  var canConfigureExactMatch: Bool {
    false
  }
}

struct SongsListFromPredicates : SongsList {
  let predicates: [MyMPMediaPropertyPredicate]
  
  func songs() -> [MPMediaItem] {
    []
  }
  
  var shouldShowSearchCriteria: Bool {
    predicates.count > 1
  }
  var canConfigureExactMatch: Bool {
    predicates.count == 1
  }
}
