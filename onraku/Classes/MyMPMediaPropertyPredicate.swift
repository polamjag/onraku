//
//  MyMPMediaPropertyPredicate.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation
import MediaPlayer

struct MyMPMediaPropertyPredicate: Identifiable {
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
        return (value as! String) + String(forProperty.hashValue) + String(comparisonType.hashValue)
    }
}

func getNextSearchHints(from filterPredicate: MyMPMediaPropertyPredicate)
    -> [MyMPMediaPropertyPredicate]
{
    switch filterPredicate.forProperty {
    case MPMediaItemPropertyGenre:
        return getNextSearchHintsOfSubGenreLike(from: filterPredicate)
    case MPMediaItemPropertyArtist:
        return getNextSearchHintsOfSubArtistsLike(from: filterPredicate)
            + getNextSearchHintsOfSubArtistsLike(from: filterPredicate, requiredMinItems: 0).map {
                MyMPMediaPropertyPredicate(
                    value: $0.value,
                    forProperty: MPMediaItemPropertyComposer,
                    comparisonType: $0.comparisonType
                )
            }
    case MPMediaItemPropertyComposer:
        return getNextSearchHintsOfSubArtistsLike(from: filterPredicate)
            + getNextSearchHintsOfSubArtistsLike(from: filterPredicate, requiredMinItems: 0).map {
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
    from filterPredicate: MyMPMediaPropertyPredicate, requiredMinItems: Int = 1
) -> [MyMPMediaPropertyPredicate] {
    if let filterVal = filterPredicate.value as? String {
        let splittedFilterVal = filterVal.intelligentlySplitIntoSubArtists()
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
