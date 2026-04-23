//
//  Player.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import MediaPlayer
import SwiftUI

extension Notification.Name {
  static let musicPlayerNowPlayingItemDidChange = Notification.Name(
    "MPMusicPlayerControllerNowPlayingItemDidChangeNotification")
}

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

struct QuickDigData {
  let songs: [MPMediaItem]
  let predicates: [MyMPMediaPropertyPredicate]
}

protocol PlaybackNotificationManaging {
  func beginGeneratingPlaybackNotifications()
  func endGeneratingPlaybackNotifications()
}

protocol QuickDigLoading {
  func loadQuickDig() async -> QuickDigData?
}

protocol NowPlayingLoading {
  func loadNowPlayingSong() async -> MPMediaItem?
}

struct SystemPlaybackNotificationManager: PlaybackNotificationManaging {
  func beginGeneratingPlaybackNotifications() {
    MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
  }

  func endGeneratingPlaybackNotifications() {
    MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
  }
}

struct SystemQuickDigLoader: QuickDigLoading {
  func loadQuickDig() async -> QuickDigData? {
    guard let now = getNowPlayingSong() else { return nil }
    let result = await getDiggedItems(of: now, includeGenre: false, withDepth: 1)
    return QuickDigData(songs: result.items, predicates: result.predicates)
  }
}

struct SystemNowPlayingLoader: NowPlayingLoading {
  func loadNowPlayingSong() async -> MPMediaItem? {
    getNowPlayingSong()
  }
}

@MainActor
final class ContentViewModel: ObservableObject {
  @Published private(set) var quickDigSongs: [MPMediaItem] = []
  @Published private(set) var quickDigPredicates: [MyMPMediaPropertyPredicate] = []

  private let playbackNotificationManager: PlaybackNotificationManaging
  private let quickDigLoader: QuickDigLoading
  private var isGeneratingPlaybackNotifications = false

  init(
    playbackNotificationManager: PlaybackNotificationManaging =
      SystemPlaybackNotificationManager(),
    quickDigLoader: QuickDigLoading = SystemQuickDigLoader()
  ) {
    self.playbackNotificationManager = playbackNotificationManager
    self.quickDigLoader = quickDigLoader
  }

  func onAppear() {
    startPlaybackNotificationsIfNeeded()
  }

  func onDisappear() {
    stopPlaybackNotificationsIfNeeded()
  }

  func handleNowPlayingItemDidChange() async {
    await refreshQuickDig()
  }

  func handleScenePhaseChange(_ newPhase: ScenePhase) async {
    switch newPhase {
    case .active:
      startPlaybackNotificationsIfNeeded()
      await refreshQuickDig()
    default:
      stopPlaybackNotificationsIfNeeded()
    }
  }

  private func startPlaybackNotificationsIfNeeded() {
    guard !isGeneratingPlaybackNotifications else { return }
    playbackNotificationManager.beginGeneratingPlaybackNotifications()
    isGeneratingPlaybackNotifications = true
  }

  private func stopPlaybackNotificationsIfNeeded() {
    guard isGeneratingPlaybackNotifications else { return }
    playbackNotificationManager.endGeneratingPlaybackNotifications()
    isGeneratingPlaybackNotifications = false
  }

  private func refreshQuickDig() async {
    guard let quickDig = await quickDigLoader.loadQuickDig() else { return }
    quickDigSongs = quickDig.songs
    quickDigPredicates = quickDig.predicates
  }
}

@MainActor
final class NowPlayingViewModel: ObservableObject {
  @Published private(set) var nowPlayingItem: MPMediaItem?
  @Published private(set) var loadingState: LoadingState = .initial

  private let nowPlayingLoader: NowPlayingLoading
  private var isAppearing = false

  init(nowPlayingLoader: NowPlayingLoading = SystemNowPlayingLoader()) {
    self.nowPlayingLoader = nowPlayingLoader
  }

  func onAppear() {
    isAppearing = true
  }

  func onDisappear() {
    isAppearing = false
  }

  func handleNowPlayingItemDidChange() async {
    guard isAppearing else { return }
    await refreshNowPlayingSong()
  }

  func handleScenePhaseChange(_ newPhase: ScenePhase) async {
    guard newPhase == .active else { return }
    await refreshNowPlayingSong()
  }

  func refreshNowPlayingSong() async {
    loadingState = .loading
    nowPlayingItem = await nowPlayingLoader.loadNowPlayingSong()
    loadingState = .loaded
  }
}
