//
//  MPMediaPlaylist+Extension.swift
//  Bohren
//
//  Created by Satoru Abe on 2025/01/04.
//

import Foundation
import MediaPlayer

func mediaEntityPersistentID(fromRawValue raw: Any?) -> MPMediaEntityPersistentID? {
  if let val = raw as? UInt64 {
    return val
  } else if let val = raw as? Int64 {
    return UInt64(bitPattern: val)
  } else if let val = raw as? UInt {
    return UInt64(val)
  } else if let val = raw as? Int {
    return UInt64(bitPattern: Int64(val))
  } else if let val = raw as? NSNumber {
    return UInt64(bitPattern: val.int64Value)
  } else {
    return nil
  }
}

// https://openradar.appspot.com/29521032
extension MPMediaPlaylist {
  public var isFolder: Bool {
    return self.value(forProperty: "isFolder") as? Bool ?? false
  }

  public var parentPersistentID: MPMediaEntityPersistentID? {
    mediaEntityPersistentID(fromRawValue: self.value(forProperty: "parentPersistentID"))
  }

  public var hasParent: Bool {
    self.parentPersistentID != nil && self.parentPersistentID != 0
  }
}
