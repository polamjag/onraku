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
}

func sortSongs(songs: [MPMediaItem], by key: SongsSortKey) async -> [MPMediaItem] {
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
        default:
            return songs
        }
    }

    do {
        return try await task.result.get()
    } catch {
        return []
    }
}
