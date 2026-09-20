//
//  SongsSorter.swift
//  onraku
//
//  Created by Satoru Abe on 2022/11/20.
//

import Foundation
import MediaPlayer

private struct SongSortSnapshot: Sendable {
  let index: Int
  let title: String
  let album: String
  let artist: String
  let genre: String
  let userGrouping: String
  let dateAdded: Date
  let bpm: Int
  let lastPlayedDate: Date?
  let playCount: Int
}

enum SongsSortKey: String, Equatable, CaseIterable {
  case none = "Default"
  case title = "Title"
  case album = "Album"
  case artist = "Artist"
  case genre = "Genre"
  case userGrouping = "User Grouping"
  case addedAt = "Date Added"
  case bpm = "BPM"
  case lastPlayedDesc = "Most Recently Played"
  case lastPlayedAsc = "Least Recently Played"
  case playCountDesc = "Most Played"
  case playCountAsc = "Least Played"
  case playCountPerDayDesc = "Most Frequently Played"
  case playCountPerDayAsc = "Least Frequently Played"

  func tertiaryInfo(for item: SongDetailLike, now: Date = Date()) -> String? {
    switch self {
    case .none, .title, .artist:
      return nil
    case .album:
      return item.albumTitle ?? "-"
    case .genre:
      return item.genre ?? "-"
    case .userGrouping:
      return item.userGrouping ?? "-"
    case .addedAt:
      return item.dateAdded.formatted(date: .abbreviated, time: .omitted)
    case .bpm:
      return item.beatsPerMinute == 0 ? "-" : String(item.beatsPerMinute)
    case .lastPlayedAsc, .lastPlayedDesc:
      return item.lastPlayedDate?.formatted(date: .abbreviated, time: .omitted)
        ?? "-"
    case .playCountAsc, .playCountDesc:
      return "\(item.playCount) plays"
    case .playCountPerDayDesc, .playCountPerDayAsc:
      let days = Int(item.dateAdded.distance(to: now) / 60 / 60 / 24)
      let playsPerDay = Double(item.playCount) / (item.dateAdded.distance(to: now) / 60 / 60 / 24)
      return "\(item.playCount) / \(days)d = \(String(format: "%.4f", playsPerDay))"
    }
  }
}

@MainActor
func sortSongs(songs: [MPMediaItem], by key: SongsSortKey) async
  -> [MPMediaItem]
{
  let snapshots = songs.enumerated().map { index, song in
    SongSortSnapshot(
      index: index,
      title: song.title ?? "",
      album: song.albumTitle ?? "",
      artist: song.artist ?? "",
      genre: song.genre ?? "",
      userGrouping: song.userGrouping ?? "",
      dateAdded: song.dateAdded,
      bpm: song.beatsPerMinuteForSorting,
      lastPlayedDate: song.lastPlayedDate,
      playCount: song.playCount
    )
  }

  let task = Task.detached(priority: .high) { () -> [Int] in
    guard !Task.isCancelled else { return [] }
    let sorted: [SongSortSnapshot]
    switch key {
    case .addedAt:
      sorted = snapshots.sorted { $0.dateAdded < $1.dateAdded }
    case .title:
      sorted = snapshots.sorted { $0.title < $1.title }
    case .album:
      sorted = snapshots.sorted { $0.album < $1.album }
    case .artist:
      sorted = snapshots.sorted { $0.artist < $1.artist }
    case .genre:
      sorted = snapshots.sorted { $0.genre < $1.genre }
    case .userGrouping:
      sorted = snapshots.sorted { $0.userGrouping < $1.userGrouping }
    case .bpm:
      sorted = snapshots.sorted { $0.bpm < $1.bpm }
    case .lastPlayedAsc:
      sorted = snapshots.sorted {
        switch ($0.lastPlayedDate, $1.lastPlayedDate) {
        case let (lhs?, rhs?): return lhs < rhs
        case (nil, nil): return false
        case (nil, _): return false
        case (_, nil): return true
        }
      }
    case .lastPlayedDesc:
      sorted = snapshots.sorted {
        switch ($0.lastPlayedDate, $1.lastPlayedDate) {
        case let (lhs?, rhs?): return lhs > rhs
        case (nil, nil): return false
        case (nil, _): return false
        case (_, nil): return true
        }
      }
    case .playCountAsc:
      sorted = snapshots.sorted { $0.playCount < $1.playCount }
    case .playCountDesc:
      sorted = snapshots.sorted { $0.playCount > $1.playCount }
    case .playCountPerDayDesc:
      let now = Date()
      sorted = snapshots.sorted {
        (Double($0.playCount) / $0.dateAdded.distance(to: now))
          > (Double($1.playCount) / $1.dateAdded.distance(to: now))
      }
    case .playCountPerDayAsc:
      let now = Date()
      sorted = snapshots.sorted {
        (Double($0.playCount) / $0.dateAdded.distance(to: now))
          < (Double($1.playCount) / $1.dateAdded.distance(to: now))
      }
    default:
      sorted = snapshots
    }

    return sorted.map(\.index)
  }

  let sortedIndexes = await withTaskCancellationHandler {
    await task.value
  } onCancel: {
    task.cancel()
  }

  guard !Task.isCancelled else { return [] }
  return sortedIndexes.map { songs[$0] }
}
