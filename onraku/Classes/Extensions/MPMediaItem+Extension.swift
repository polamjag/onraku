//
//  MPMediaItem+Extension.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation
import MediaPlayer

extension MPMediaItem: @retroactive Identifiable {
  public var id: MPMediaEntityPersistentID {
    return self.persistentID
  }

  public var beatsPerMinuteForSorting: Int {
    self.beatsPerMinute == 0 ? Int.max : self.beatsPerMinute
  }

  public var releaseYear: Int? {
    // https://stackoverflow.com/questions/45254471/release-date-of-mpmediaitem-returning-nil-swift-4
    if let yearNumber: NSNumber = self.value(forProperty: "year") as? NSNumber,
      yearNumber.isKind(of: NSNumber.self)
    {
      let year = yearNumber.intValue
      if year != 0 {
        return year
      }
    }
    return nil
  }
}
