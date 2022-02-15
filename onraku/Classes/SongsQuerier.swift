//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer

enum CollectionType: String, Equatable, CaseIterable {
    case playlist = "Playlist"
    case album = "Album"
    case artist = "Artist"
    case genre = "Genre"
    case userGrouping = "User Grouping"

    func getQueryForType() -> MPMediaQuery? {
        switch self {
        case .userGrouping:
            return nil
        case .playlist:
            return MPMediaQuery.playlists()
        case .genre:
            return MPMediaQuery.genres()
        case .artist:
            return MPMediaQuery.artists()
        case .album:
            return MPMediaQuery.albums()
        }
    }

    var systemImageName: String {
        switch self {
        case .playlist:
            return "list.dash"
        case .album:
            return "square.stack"
        case .genre:
            return "guitars"
        case .artist:
            return "music.mic"
        case .userGrouping:
            return "rectangle.3.group"
        }
    }

    var queryPredicateType: String? {
        switch self {
        case .userGrouping:
            return MPMediaItemPropertyUserGrouping
        case .artist:
            return MPMediaItemPropertyArtist
        case .album:
            return MPMediaItemPropertyAlbumTitle
        case .genre:
            return MPMediaItemPropertyGenre
        case .playlist:
            return nil
        }
    }
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

    func getFilterPredicate() -> MyMPMediaPropertyPredicate? {
        if let forProperty = type.queryPredicateType {
            return MyMPMediaPropertyPredicate(
                value: name,
                forProperty: forProperty,
                comparisonType: .equalTo
            )
        }
        return nil
    }
}

func loadSongsCollectionsOf(_ type: CollectionType) async -> [SongsCollection] {
    let task = Task.detached(priority: .high) { () -> [SongsCollection] in
        switch type {
        case .playlist, .genre, .artist, .album:
            return loadAllCollectionsOf(type)
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

private func loadAllCollectionsOf(_ type: CollectionType) -> [SongsCollection] {
    let a = type.getQueryForType()!.collections ?? []
    return a.map {
        return SongsCollection(
            name: $0.getCollectionName(as: type) ?? "",
            id: String($0.persistentID),
            type: type,
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
        return try await task.result.get().filter { $0.mediaType == MPMediaType.music }
    } catch {
        return []
    }
}

private func getSongsByUserGrouping(
    userGrouping: String, comparisonType: MPMediaPredicateComparison
)
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

private struct SongWithPredicate {
    let song: MPMediaItem
    let predicate: MyMPMediaPropertyPredicate
}

private struct SongAndPredicates {
    let song: MPMediaItem
    var predicates: [MyMPMediaPropertyPredicate]
}

private func superIntelligentSort(src: [SongWithPredicate]) -> [MPMediaItem] {
    var dic: Dictionary<MPMediaEntityPersistentID, SongAndPredicates> = [:]
    for x in src {
        if dic[x.song.persistentID] != nil {
            dic[x.song.persistentID]?.predicates.append(x.predicate)
        } else {
            dic[x.song.persistentID] = SongAndPredicates(song: x.song, predicates: [x.predicate])
        }
    }
    
    return dic.sorted { $0.value.predicates.count > $1.value.predicates.count }.map{ $0.value.song }
}

func getRelevantItems(of item: MPMediaItem, includeGenre: Bool) async -> [MPMediaItem] {
    var filterPreds: [MyMPMediaPropertyPredicate] = [
        MyMPMediaPropertyPredicate(
            value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .equalTo),
        MyMPMediaPropertyPredicate(
            value: item.artist, forProperty: MPMediaItemPropertyArtist,
            comparisonType: .contains),
        MyMPMediaPropertyPredicate(
            value: item.composer, forProperty: MPMediaItemPropertyComposer,
            comparisonType: .contains),
        MyMPMediaPropertyPredicate(
            value: item.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle,
            comparisonType: .equalTo),
        MyMPMediaPropertyPredicate(
            value: item.albumArtist, forProperty: MPMediaItemPropertyAlbumArtist,
            comparisonType: .contains),

    ]
    if includeGenre {
        filterPreds += [
            MyMPMediaPropertyPredicate(
                value: item.userGrouping, forProperty: MPMediaItemPropertyUserGrouping,
                comparisonType: .contains),
            MyMPMediaPropertyPredicate(
                value: item.genre, forProperty: MPMediaItemPropertyGenre,
                comparisonType: .contains),
        ]
    }

    let allFilters: [MyMPMediaPropertyPredicate] =
        (filterPreds.flatMap { [$0] + $0.getNextSearchHints() }).filter {
            if let s = $0.value as? String, !s.isEmpty {
                return true
            } else {
                return false
            }
        }.unique()

    do {
        return try await withThrowingTaskGroup(of: [SongWithPredicate].self) { group in
            for pred in allFilters {
                group.addTask(priority: .high) {
                    return await getSongsByPredicate(predicate: pred).map {
                        SongWithPredicate(song: $0, predicate: pred)
                    }
                }
            }
            var items: [SongWithPredicate] = []
            for try await (gotItems) in group {
                items += gotItems
            }
            return superIntelligentSort(src: items).unique().filter { $0 != item }
        }
    } catch {
        return []
    }
}
