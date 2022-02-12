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
            return await loadPlaylist()
        case .userGrouping:
            return await loadGroupings()
        }
    }
    
    do {
        return try await task.result.get()
    } catch {
        return []
    }
}

func loadPlaylist() async -> [Playlist] {
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

func loadGroupings() async -> [Playlist] {
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

func getNowPlayingSong() -> MPMediaItem? {
    return MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
}
