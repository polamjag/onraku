//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer

func loadPlaylistsForType(type: NavigationDestinationType) async -> [Playlist] {
    let task = Task<[Playlist], Error>.detached(priority: .high) {
        switch (type) {
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

func loadPlaylist() -> [Playlist] {
    let playlistsQuery = MPMediaQuery.playlists().collections ?? []
    return playlistsQuery.map {
        Playlist(
            name: $0.value(forProperty: MPMediaPlaylistPropertyName)! as! String,
            id: String($0.representativeItem?.persistentID ?? 0),
            navigationDestinationInfo: NavigationDestinationInfo(
                type: .playlist, songs: $0.items
            )
        )
    }
}

func loadGroupings() -> [Playlist] {
    let songs = MPMediaQuery.songs().items
    let songsByGrouping = songs?.reduce([String:[MPMediaItem]](), {
        var prev = $0
        let gr = $1.userGrouping ?? ""
        prev[gr] = (prev[gr] ?? []) + [$1]
        return prev
    })
    if (songsByGrouping == nil) { return [] }
    return songsByGrouping!.keys.sorted().map {
        return Playlist(
            name: $0,
            id: $0,
            navigationDestinationInfo: NavigationDestinationInfo(
                type: .userGrouping,
                songs: songsByGrouping?[$0] ?? []
            )
        )
    }
}

struct MyMPMediaPropertyPredicate {
    let value: Any?
    let forProperty: String
}

func getSongsByPredicate(predicate: MyMPMediaPropertyPredicate) async -> [MPMediaItem] {
    let task = Task<[MPMediaItem], Error>.detached(priority: .high) {
        if (predicate.forProperty == MPMediaItemPropertyUserGrouping) {
            if let s = predicate.value as? String {
                return getSongsByUserGrouping(userGrouping: s)
            } else {
                return []
            }
        } else {
            return MPMediaQuery(filterPredicates: Set([MPMediaPropertyPredicate(value: predicate.value, forProperty: predicate.forProperty)])).items ?? []
        }
    }

    do {
        return try await task.result.get()
    } catch {
        return []
    }
}

func getSongsByUserGrouping(userGrouping: String) -> [MPMediaItem] {
    let songs = MPMediaQuery.songs().items ?? []
    return songs.filter{ $0.userGrouping?.contains(userGrouping) ?? false }
}

func getNowPlayingSong() -> MPMediaItem? {
    return MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
}
