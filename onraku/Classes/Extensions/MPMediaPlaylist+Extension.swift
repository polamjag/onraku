//
//  MPMediaPlaylist+Extension.swift
//  Bohren
//
//  Created by Satoru Abe on 2025/01/04.
//

import Foundation
import MediaPlayer

// https://openradar.appspot.com/29521032
extension MPMediaPlaylist {
  public var isFolder: Bool {
    return self.value(forProperty: "isFolder") as? Bool ?? false
  }

  public var parentPersistentID: MPMediaEntityPersistentID? {
    if let raw = self.value(forProperty: "parentPersistentID") {
      if let val = raw as? UInt64 {
        return val
      } else if let val = raw as? Int64 {
        return UInt64(Int64.max + val + 1)
      } else {
        return nil
      }
    } else {
      return nil
    }
  }
  
  public var hasParent: Bool {
    self.parentPersistentID != nil && self.parentPersistentID != 0
  }
}
