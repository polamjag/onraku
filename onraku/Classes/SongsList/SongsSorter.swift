//
//  SongsSorter.swift
//  onraku
//
//  Created by Satoru Abe on 2022/11/20.
//

import Foundation
import MediaPlayer

enum SongsSortKey: String, Equatable, CaseIterable {
  case none = "Default"
  case title = "Title"
  case album = "Album"
  case artist = "Artist"
  case genre = "Genre"
  case userGrouping = "User Grouping"
  case addedAt = "Date Added"
  case bpm = "BPM"
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
    case .playCountAsc, .playCountDesc:
      return "\(item.playCount) plays"
    case .playCountPerDayDesc, .playCountPerDayAsc:
      let days = Int(item.dateAdded.distance(to: now) / 60 / 60 / 24)
      let playsPerDay = Double(item.playCount) / (item.dateAdded.distance(to: now) / 60 / 60 / 24)
      return "\(item.playCount) / \(days)d = \(String(format: "%.4f", playsPerDay))"
    }
  }
}

func sortSongs(songs: [MPMediaItem], by key: SongsSortKey) async
  -> [MPMediaItem]
{
  let task = Task.detached(priority: .high) { () -> [MPMediaItem] in
    switch key {
    case .addedAt:
      return songs.sorted { $0.dateAdded < $1.dateAdded }
    case .title:
      return songs.sorted { $0.title ?? "" < $1.title ?? "" }
    case .album:
      return songs.sorted { $0.albumTitle ?? "" < $1.albumTitle ?? "" }
    case .artist:
      return songs.sorted { $0.artist ?? "" < $1.artist ?? "" }
    case .genre:
      return songs.sorted { $0.genre ?? "" < $1.genre ?? "" }
    case .userGrouping:
      return songs.sorted { $0.userGrouping ?? "" < $1.userGrouping ?? "" }
    case .bpm:
      return songs.sorted {
        $0.beatsPerMinuteForSorting
          < $1.beatsPerMinuteForSorting
      }
    case .playCountAsc:
      return songs.sorted { $0.playCount < $1.playCount }
    case .playCountDesc:
      return songs.sorted { $0.playCount > $1.playCount }
    case .playCountPerDayDesc:
      let now = Date()
      return songs.sorted {
        return (Double($0.playCount) / $0.dateAdded.distance(to: now))
          > (Double($1.playCount) / $1.dateAdded.distance(to: now))
      }
    case .playCountPerDayAsc:
      let now = Date()
      return songs.sorted {
        return (Double($0.playCount) / $0.dateAdded.distance(to: now))
          < (Double($1.playCount) / $1.dateAdded.distance(to: now))
      }
    default:
      return songs
    }
  }

  return await task.result.get()
}
