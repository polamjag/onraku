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
  let currentRepeatMode = MPMusicPlayerController.systemMusicPlayer.repeatMode
  MPMusicPlayerController.systemMusicPlayer.setQueue(with: collection)
  MPMusicPlayerController.systemMusicPlayer.play()
  MPMusicPlayerController.systemMusicPlayer.repeatMode = currentRepeatMode
}

func appendMediaItems(items: [MPMediaItem]) {
  let collection = MPMediaItemCollection.init(items: items)
  let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
  MPMusicPlayerController.systemMusicPlayer.append(qd)
}

func prependMediaItems(items: [MPMediaItem]) {
  let collection = MPMediaItemCollection.init(items: items)
  let qd = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: collection)
  MPMusicPlayerController.systemMusicPlayer.prepend(qd)
}

func getNowPlayingSong() -> MPMediaItem? {
  return MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
}
