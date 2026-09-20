//
//  SongsQuerier.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer
import RegexBuilder

@MainActor
func getSongsByPredicateNow(predicate: MyMPMediaPropertyPredicate) -> [MPMediaItem] {
  if predicate.forProperty == MPMediaItemPropertyComments {
    guard let query = predicate.value as? String else { return [] }
    return getSongsByComments(query: query, comparisonType: predicate.comparisonType)
  } else if predicate.forProperty == MPMediaItemPropertyUserGrouping {
    if let s = predicate.value as? String {
      return getSongsByUserGrouping(
        userGrouping: s,
        comparisonType: predicate.comparisonType
      )
    } else {
      return []
    }
  } else {
    let items =
      MPMediaQuery(
        filterPredicates: Set([
          MPMediaPropertyPredicate(
            value: predicate.value,
            forProperty: predicate.forProperty,
            comparisonType: predicate.comparisonType
          )
        ])
      ).items ?? []

    if items.isEmpty {
      return []
    }

    if let stringPredicateValue = predicate.value as? String {
      let regex = Regex {
        /\b/
        stringPredicateValue
        /\b/
      }

      return items.filter {
        if let val = $0.value(forProperty: predicate.forProperty) as? String {
          let matches = val.matches(of: regex)
          return !matches.isEmpty
        } else {
          return true
        }
      }
    } else {
      return items
    }
  }
}

@MainActor
func getSongsByPredicate(predicate: MyMPMediaPropertyPredicate) async
  -> [MPMediaItem]
{
  guard !Task.isCancelled else { return [] }
  return getSongsByPredicateNow(predicate: predicate).filter {
    $0.mediaType == MPMediaType.music
  }
}

@MainActor
private func getSongsByComments(
  query: String, comparisonType: MPMediaPredicateComparison
)
  -> [MPMediaItem]
{
  let songs = MPMediaQuery.songs().items ?? []

  switch comparisonType {
  case .equalTo:
    return songs.filter { ($0.comments ?? "") == query }
  case .contains:
    return songs.filter { $0.comments?.contains(query) ?? false }
  @unknown default:
    return songs.filter { $0.comments?.contains(query) ?? false }
  }
}

@MainActor
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
