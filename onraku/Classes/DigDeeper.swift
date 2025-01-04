//
//  RelevantSongs.swift
//  onraku
//
//  Created by Satoru Abe on 2022/11/20.
//

import Foundation
import MediaPlayer

private struct SongWithPredicate {
  let song: MPMediaItem
  let predicate: MyMPMediaPropertyPredicate
}

private struct SongAndPredicates {
  let song: MPMediaItem
  var predicates: [MyMPMediaPropertyPredicate]

  var sortScore: Float {
    self.predicates.reduce(0) { res, pred in
      switch pred.forProperty {
      case MPMediaItemPropertyUserGrouping:
        return 0.5 + res
      case MPMediaItemPropertyGenre:
        return 0.2 + res
      default:
        return 1 + res

      }
    }
  }
}

private func sortByItemRelevance(src: [SongWithPredicate]) -> [MPMediaItem] {
  var dic: [MPMediaEntityPersistentID: SongAndPredicates] = [:]
  for x in src {
    if dic[x.song.persistentID] != nil {
      dic[x.song.persistentID]?.predicates.append(x.predicate)
    } else {
      dic[x.song.persistentID] = SongAndPredicates(
        song: x.song, predicates: [x.predicate])
    }
  }

  // make songs with same score shuffled
  return dic.shuffled().sorted { $0.value.sortScore > $1.value.sortScore }.map {
    $0.value.song
  }
}

private func getDiggingQuery(for item: MPMediaItem, includeGenre: Bool)
  -> [MyMPMediaPropertyPredicate]
{
  var filterPreds: [MyMPMediaPropertyPredicate] =
    (item.title?.intelligentlyExtractRemixersCredit().map {
      MyMPMediaPropertyPredicate(
        value: $0, forProperty: MPMediaItemPropertyArtist)
    } ?? [])
    + (item.title?.intelligentlyExtractFeaturedArtists().map {
      MyMPMediaPropertyPredicate(
        value: $0, forProperty: MPMediaItemPropertyArtist)
    } ?? [])
    + [
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

  return allFilters
}

private func queryMultiPredicates(predicates: [MyMPMediaPropertyPredicate])
  async
  -> [SongWithPredicate]
{
  var songsWithPreds: [SongWithPredicate] = []

  do {
    try await withThrowingTaskGroup(of: [SongWithPredicate].self) { group in
      for pred in predicates {
        group.addTask(priority: .high) {
          return await getSongsByPredicate(predicate: pred).map {
            SongWithPredicate(song: $0, predicate: pred)
          }
        }
      }
      for try await (gotItems) in group {
        songsWithPreds += gotItems
      }
    }
  } catch {
  }

  return songsWithPreds
}

func getDiggedItems(
  of item: MPMediaItem, includeGenre: Bool, withDepth depth: Int = 1
) async
  -> (items: [MPMediaItem], predicates: [MyMPMediaPropertyPredicate])
{
  let allPredicates = getDiggingQuery(for: item, includeGenre: includeGenre)

  var firstResult = await queryMultiPredicates(predicates: allPredicates)

  var usedPredicates = allPredicates

  if depth > 1 {
    for _ in 2...depth {
      let relevantItemsQuery = firstResult.flatMap { sp in
        getDiggingQuery(for: sp.song, includeGenre: includeGenre)
      }.unique()
      firstResult += await queryMultiPredicates(predicates: relevantItemsQuery)
      usedPredicates += relevantItemsQuery
    }
  }

  let sorted = sortByItemRelevance(src: firstResult).unique().filter {
    $0 != item
  }

  return (sorted, usedPredicates)
}
