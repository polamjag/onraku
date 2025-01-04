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
  
  public var parentPersistentID: String? {
    return self.value(forProperty: "parentPersistentID") as? String
  }
}
