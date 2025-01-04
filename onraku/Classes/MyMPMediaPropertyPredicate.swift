//
//  MyMPMediaPropertyPredicate.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation
import MediaPlayer

struct MyMPMediaPropertyPredicate: Identifiable, Hashable {
  static func == (
    lhs: MyMPMediaPropertyPredicate, rhs: MyMPMediaPropertyPredicate
  ) -> Bool {
    return lhs.id == rhs.id
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }

  var value: Any?
  var forProperty: String
  var comparisonType: MPMediaPredicateComparison = .equalTo

  var friendryLabel: String?

  var someFriendlyLabel: String {
    if let friendryLabel = self.friendryLabel {
      return friendryLabel
    } else if let str = self.value as? String {
      return "\(forProperty): \(str)"
    }
    return "<unknown>"
  }

  var id: String {
    if let value = value as? String {
      return value + String(forProperty.hashValue)
        + String(comparisonType.hashValue)
    } else if let value = value as? UInt64 {
      return String(value) + String(forProperty.hashValue)
        + String(comparisonType.hashValue)
    } else {
      return String(forProperty.hashValue)
        + String(comparisonType.hashValue)
    }
  }
  
  var systemImageNameForProperty: String? {
    switch self.forProperty {
    case MPMediaItemPropertyAlbumTitle:
      return "square.stack"
    case MPMediaItemPropertyGenre:
      return "guitars"
    case MPMediaItemPropertyArtist:
      return "music.microphone"
    case MPMediaItemPropertyAlbumArtist:
      return "music.microphone"
    case MPMediaItemPropertyTitle:
      return "music.note"
    case MPMediaItemPropertyComposer:
      return "music.quarternote.3"
    case MPMediaItemPropertyUserGrouping:
      return "latch.2.case"
    default:
      return nil
    }
  }
  
  var humanReadableForProperty: String {
    switch self.forProperty {
    case MPMediaItemPropertyAlbumTitle:
      return "Album"
    case MPMediaItemPropertyGenre:
      return "Genre"
    case MPMediaItemPropertyArtist:
      return "Artist"
    case MPMediaItemPropertyAlbumArtist:
      return "Album Artist"
    case MPMediaItemPropertyTitle:
      return "Title"
    case MPMediaItemPropertyComposer:
      return "Composer"
    case MPMediaItemPropertyUserGrouping:
      return "User Grouping"
    default:
      return self.forProperty
    }
  }

  func getNextSearchHints() -> [MyMPMediaPropertyPredicate] {
    switch self.forProperty {
    case MPMediaItemPropertyGenre:
      return getNextSearchHintsOfSubGenreLike(from: self)
    case MPMediaItemPropertyArtist:
      let min = getNextSearchHintsOfSubArtistsLike(
        from: self, requiredMinItems: 0)
      return getNextSearchHintsOfSubArtistsLike(from: self)
        + min.map {
          MyMPMediaPropertyPredicate(
            value: $0.value,
            forProperty: MPMediaItemPropertyTitle,
            comparisonType: .contains
          )
        }
        + min.map {
          MyMPMediaPropertyPredicate(
            value: $0.value,
            forProperty: MPMediaItemPropertyComposer,
            comparisonType: $0.comparisonType
          )
        }
    case MPMediaItemPropertyComposer:
      return getNextSearchHintsOfSubArtistsLike(from: self)
        + getNextSearchHintsOfSubArtistsLike(from: self, requiredMinItems: 0)
        .map {
          MyMPMediaPropertyPredicate(
            value: $0.value,
            forProperty: MPMediaItemPropertyArtist,
            comparisonType: $0.comparisonType
          )
        }
    default:
      return []
    }
  }
}

private func getNextSearchHintsOfSubGenreLike(
  from filterPredicate: MyMPMediaPropertyPredicate, requiredMinItems: Int = 1
) -> [MyMPMediaPropertyPredicate] {
  if let filterVal = filterPredicate.value as? String {
    let splittedFilterVal = filterVal.intelligentlySplitIntoSubGenres()
    if splittedFilterVal.count > requiredMinItems {
      return splittedFilterVal.map {
        MyMPMediaPropertyPredicate(
          value: $0,
          forProperty: filterPredicate.forProperty,
          comparisonType: .contains
        )
      }
    }
  }
  return []
}

private func getNextSearchHintsOfSubArtistsLike(
  from filterPredicate: MyMPMediaPropertyPredicate, requiredMinItems: Int = 1,
  requiredMinItemLength: Int = 2
) -> [MyMPMediaPropertyPredicate] {
  if let filterVal = filterPredicate.value as? String {
    let splittedFilterVal = filterVal.intelligentlySplitIntoSubArtists().filter
    {
      $0.count >= requiredMinItemLength
    }
    if splittedFilterVal.count > requiredMinItems {
      return splittedFilterVal.map {
        MyMPMediaPropertyPredicate(
          value: $0,
          forProperty: filterPredicate.forProperty,
          comparisonType: .contains
        )
      }
    }
  }
  return []
}
