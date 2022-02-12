//
//  Player.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer

func playMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    MPMusicPlayerController.systemMusicPlayer.setQueue(with: collection)
    MPMusicPlayerController.systemMusicPlayer.play()
}

func appendMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
    MPMusicPlayerController.systemMusicPlayer.append(qd)
    MPMusicPlayerController.systemMusicPlayer.play()
}

func prependMediaItems(items: [MPMediaItem]) {
    let collection = MPMediaItemCollection.init(items: items)
    let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
    MPMusicPlayerController.systemMusicPlayer.prepend(qd)
    MPMusicPlayerController.systemMusicPlayer.play()
}
