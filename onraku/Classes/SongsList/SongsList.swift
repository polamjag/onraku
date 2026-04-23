//
//  SongsList.swift
//  onraku
//
//  Created by Satoru Abe on 2026/01/10.
//

import MediaPlayer

protocol SongsList {
  var title: String { get }
  var searchCriteria: [MyMPMediaPropertyPredicate] { get }
  func loadSongs() async -> [MPMediaItem]
}

extension SongsList {
  var shouldShowSearchCriteria: Bool {
    searchCriteria.count > 1
  }
}

struct SongsListFixed: SongsList {
  let fixedSongs: [MPMediaItem]
  let title: String

  var searchCriteria: [MyMPMediaPropertyPredicate] {
    []
  }

  func loadSongs() async -> [MPMediaItem] {
    fixedSongs
  }
}

struct SongsListLoaded: SongsList {
  let loadedSongs: [MPMediaItem]
  let title: String
  let predicates: [MyMPMediaPropertyPredicate]

  var searchCriteria: [MyMPMediaPropertyPredicate] {
    predicates
  }

  func loadSongs() async -> [MPMediaItem] {
    loadedSongs
  }
}

struct SongsListFromPlaylist: SongsList {
  let playlist: MPMediaPlaylist

  var title: String {
    self.playlist.name ?? ""
  }

  var searchCriteria: [MyMPMediaPropertyPredicate] {
    []
  }

  func loadSongs() async -> [MPMediaItem] {
    playlist.items
  }
}

struct SongsListFromPredicates: SongsList {
  let predicates: [MyMPMediaPropertyPredicate]
  var customTitle: String?

  var title: String {
    customTitle ?? "Search Result"
  }

  var searchCriteria: [MyMPMediaPropertyPredicate] {
    predicates
  }

  func loadSongs() async -> [MPMediaItem] {
    await getSongsByPredicates(predicates)
  }
}

func predicateToSongsList(_ predicate: MyMPMediaPropertyPredicate) -> SongsList {
  SongsListFromPredicates(
    predicates: [predicate],
    customTitle: predicate.value as? String
  )
}

func getSongsByPredicates(_ predicates: [MyMPMediaPropertyPredicate]) async
  -> [MPMediaItem]
{
  let songs = await withTaskGroup(of: [MPMediaItem].self) { group in
    for predicate in predicates {
      group.addTask {
        await getSongsByPredicate(predicate: predicate)
      }
    }

    var loadedSongs: [MPMediaItem] = []
    for await result in group {
      loadedSongs += result
    }
    return loadedSongs
  }

  return songs.unique()
}
