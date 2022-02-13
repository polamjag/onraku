//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer

struct SongsCollection: Identifiable, Hashable {
    static func == (lhs: SongsCollection, rhs: SongsCollection) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let name: String
    let id: String
    let navigationDestinationInfo: NavigationDestinationInfo
}

func loadSongsCollectionsFor(type: NavigationDestinationType) async -> [SongsCollection] {
    let task = Task.detached(priority: .high) { () -> [SongsCollection] in
        switch type {
        case .playlist:
            return loadPlaylist()
        case .userGrouping:
            return loadGroupings()
        }
    }

    do {
        return try await task.result.get()
    } catch {
        return []
    }
}

func loadPlaylist() -> [SongsCollection] {
    let playlistsQuery = MPMediaQuery.playlists().collections ?? []
    return playlistsQuery.map {
        SongsCollection(
            name: $0.value(forProperty: MPMediaPlaylistPropertyName)! as! String,
            id: String($0.persistentID),
            navigationDestinationInfo: NavigationDestinationInfo(
                type: .playlist, songs: $0.items
            )
        )
    }
}

func loadGroupings() -> [SongsCollection] {
    let songs = MPMediaQuery.songs().items
    let songsByGrouping = songs?.reduce(
        [String: [MPMediaItem]](),
        {
            var prev = $0
            let gr = $1.userGrouping ?? ""
            prev[gr] = (prev[gr] ?? []) + [$1]
            return prev
        })
    if songsByGrouping == nil { return [] }
    return songsByGrouping!.keys.sorted().map {
        return SongsCollection(
            name: $0,
            id: $0,
            navigationDestinationInfo: NavigationDestinationInfo(
                type: .userGrouping,
                songs: songsByGrouping?[$0] ?? []
            )
        )
    }
}

func getSongsByPredicate(predicate: MyMPMediaPropertyPredicate) async -> [MPMediaItem] {
    let task = Task.detached(priority: .high) { () -> [MPMediaItem] in
        if predicate.forProperty == MPMediaItemPropertyUserGrouping {
            if let s = predicate.value as? String {
                return getSongsByUserGrouping(
                    userGrouping: s, comparisonType: predicate.comparisonType)
            } else {
                return []
            }
        } else {
            return
                MPMediaQuery(
                    filterPredicates: Set([
                        MPMediaPropertyPredicate(
                            value: predicate.value, forProperty: predicate.forProperty,
                            comparisonType: predicate.comparisonType)
                    ])
                ).items ?? []
        }
    }

    do {
        return try await task.result.get()
    } catch {
        return []
    }
}

func getSongsByUserGrouping(userGrouping: String, comparisonType: MPMediaPredicateComparison)
    -> [MPMediaItem]
{
    let songs = MPMediaQuery.songs().items ?? []

    switch comparisonType {
    case .equalTo:
        return songs.filter { ($0.userGrouping ?? "") == userGrouping }
    case .contains:
        return songs.filter { $0.userGrouping?.contains(userGrouping) ?? false }
    @unknown default:
        return songs.filter { $0.userGrouping?.contains(userGrouping) ?? false }
    }

}

func getNowPlayingSong() -> MPMediaItem? {
    return MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
}
