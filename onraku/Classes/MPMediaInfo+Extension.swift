//
//  MPMediaInfo+Extension.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation
import MediaPlayer

extension MPMediaItem: Identifiable {
    public var id: String {
        return String(self.persistentID)
    }
}
