//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer

enum CollectionType {
    case userGrouping, playlist
}

struct SongsCollection: Identifiable, Hashable {
    static func == (lhs: SongsCollection, rhs: SongsCollection) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let name: String
    let id: String
    let type: CollectionType
    let items: [MPMediaItem]
}

func loadSongsCollectionsFor(type: CollectionType) async -> [SongsCollection] {
    let task = Task.detached(priority: .high) { () -> [SongsCollection] in
        switch type {
        case .playlist:
            return loadAllPlaylists()
        case .userGrouping:
            return loadAllUserGroupings()
        }
    }

    do {
        return try await task.result.get()
    } catch {
        return []
    }
}

private func loadAllPlaylists() -> [SongsCollection] {
    let playlistsQuery = MPMediaQuery.playlists().collections ?? []
    return playlistsQuery.map {
        SongsCollection(
            name: $0.value(forProperty: MPMediaPlaylistPropertyName)! as! String,
            id: String($0.persistentID),
            type: .playlist,
            items: $0.items
        )
    }
}

private func loadAllUserGroupings() -> [SongsCollection] {
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
            type: .userGrouping,
            items: songsByGrouping?[$0] ?? []

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
                            value: predicate.value,
                            forProperty: predicate.forProperty,
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

private func getSongsByUserGrouping(userGrouping: String, comparisonType: MPMediaPredicateComparison)
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
