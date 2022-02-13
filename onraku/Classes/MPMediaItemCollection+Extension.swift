//
//  MPMediaItemCollection+Extension.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/13.
//

import Foundation
import MediaPlayer

extension MPMediaItemCollection {
    func getCollectionName(as type: CollectionType) -> String {
        switch type {
        case .playlist:
            return self.value(forProperty: MPMediaPlaylistPropertyName)! as! String
        case .album:
            return self.representativeItem?.albumTitle ?? ""
        case .artist:
            return self.representativeItem?.artist ?? ""
        case .genre:
            return self.representativeItem?.genre ?? ""
        default:
            return ""
        }
    }
}
