//
//  Player.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

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

enum TrackPreviewMode: String, CaseIterable, Identifiable {
    case independent
    case pauseSystem

    static let storageKey = "trackPreviewMode"
    static let defaultMode: TrackPreviewMode = .independent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .independent:
            return "Keep Music Playing"
        case .pauseSystem:
            return "Pause Music During Preview"
        }
    }

    var description: String {
        switch self {
        case .independent:
            return "Duck other audio while previewing, without changing the Music app queue."
        case .pauseSystem:
            return "Pause Music while previewing, then resume it if it was playing."
        }
    }

    static func stored(in defaults: UserDefaults = .standard) -> TrackPreviewMode {
        guard let rawValue = defaults.string(forKey: storageKey) else {
            return defaultMode
        }
        return TrackPreviewMode(rawValue: rawValue) ?? defaultMode
    }
}

protocol TrackPreviewPlaying: AnyObject {
    var playbackState: MPMusicPlaybackState { get }
    var currentPlaybackTime: TimeInterval { get set }

    func setQueue(with items: [MPMediaItem]) -> Bool
    func play()
    func pause()
    func stop()
}

final class MusicPlayerTrackPreviewPlayer: TrackPreviewPlaying {
    private let player: MPMusicPlayerController

    init(player: MPMusicPlayerController) {
        self.player = player
    }

    var playbackState: MPMusicPlaybackState {
        player.playbackState
    }

    var currentPlaybackTime: TimeInterval {
        get { player.currentPlaybackTime }
        set { player.currentPlaybackTime = newValue }
    }

    func setQueue(with items: [MPMediaItem]) -> Bool {
        guard !items.isEmpty else { return false }
        player.setQueue(with: MPMediaItemCollection(items: items))
        return true
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
    }
}

final class AVPlayerTrackPreviewPlayer: TrackPreviewPlaying {
    private let player = AVPlayer()

    var playbackState: MPMusicPlaybackState {
        guard player.currentItem != nil else { return .stopped }
        return player.timeControlStatus == .playing ? .playing : .paused
    }

    var currentPlaybackTime: TimeInterval {
        get {
            let seconds = player.currentTime().seconds
            return seconds.isFinite ? seconds : 0
        }
        set {
            player.seek(
                to: CMTime(seconds: max(0, newValue), preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        }
    }

    func setQueue(with items: [MPMediaItem]) -> Bool {
        guard
            let item = items.first,
            let assetURL = item.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
        else {
            player.replaceCurrentItem(with: nil)
            return false
        }

        player.volume = 1.0
        player.replaceCurrentItem(with: AVPlayerItem(url: assetURL))
        return true
    }

    func play() {
        player.volume = 1.0
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}

final class FallbackTrackPreviewPlayer: TrackPreviewPlaying {
    private let primaryPlayer: TrackPreviewPlaying
    private let fallbackPlayer: TrackPreviewPlaying
    private var activePlayer: TrackPreviewPlaying?

    init(
        primaryPlayer: TrackPreviewPlaying,
        fallbackPlayer: TrackPreviewPlaying
    ) {
        self.primaryPlayer = primaryPlayer
        self.fallbackPlayer = fallbackPlayer
    }

    var playbackState: MPMusicPlaybackState {
        activePlayer?.playbackState ?? .stopped
    }

    var currentPlaybackTime: TimeInterval {
        get { activePlayer?.currentPlaybackTime ?? 0 }
        set { activePlayer?.currentPlaybackTime = newValue }
    }

    func setQueue(with items: [MPMediaItem]) -> Bool {
        if primaryPlayer.setQueue(with: items) {
            activePlayer = primaryPlayer
            return true
        }

        if fallbackPlayer.setQueue(with: items) {
            activePlayer = fallbackPlayer
            return true
        }

        activePlayer = nil
        return false
    }

    func play() {
        activePlayer?.play()
    }

    func pause() {
        activePlayer?.pause()
    }

    func stop() {
        activePlayer?.stop()
        activePlayer = nil
    }
}

protocol PreviewAudioSessionConfiguring {
    var isOtherAudioPlaying: Bool { get }

    func activateForPreview(ducksOtherAudio: Bool) throws
    func deactivatePreview() throws
}

struct SystemPreviewAudioSessionConfigurator: PreviewAudioSessionConfiguring {
    var isOtherAudioPlaying: Bool {
        AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
    }

    func activateForPreview(ducksOtherAudio: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions =
            ducksOtherAudio ? [.mixWithOthers, .duckOthers] : []
        try session.setCategory(.playback, mode: .default, options: options)
        try session.setActive(true)
    }

    func deactivatePreview() throws {
        try AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
    }
}

@MainActor
final class TrackPreviewProgress: ObservableObject {
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    func update(elapsedTime: TimeInterval, duration: TimeInterval) {
        self.elapsedTime = elapsedTime
        self.duration = duration
    }

    func updateElapsedTime(_ elapsedTime: TimeInterval) {
        self.elapsedTime = elapsedTime
    }

    func reset() {
        elapsedTime = 0
        duration = 0
    }
}

@MainActor
final class TrackPreviewController: ObservableObject {
    @Published private(set) var previewingItemID: MPMediaEntityPersistentID?
    // HUD snapshot data stays non-published so ending a preview only invalidates
    // the row highlight/overlay visibility, not the whole song list.
    private(set) var previewingItem: MPMediaItem?
    private(set) var previewArtworkImage: UIImage?
    private(set) var previewTouchLocation: CGPoint?

    private(set) var previewElapsedTime: TimeInterval = 0
    private(set) var previewDuration: TimeInterval = 0
    let previewProgress = TrackPreviewProgress()

    var mode: TrackPreviewMode

    private let previewPlayer: TrackPreviewPlaying
    private let systemPlayer: TrackPreviewPlaying
    private let audioSessionConfigurator: PreviewAudioSessionConfiguring
    private var shouldResumeSystemAfterPreview = false
    private var shouldNotifyOthersAfterPreview = false
    private var progressTask: Task<Void, Never>?
    private var delayedResumeTask: Task<Void, Never>?
    private var stopCleanupTask: Task<Void, Never>?
    private let stopCleanupDelayNanoseconds: UInt64

    init(
        mode: TrackPreviewMode = TrackPreviewMode.stored(),
        previewPlayer: TrackPreviewPlaying = FallbackTrackPreviewPlayer(
            primaryPlayer: AVPlayerTrackPreviewPlayer(),
            fallbackPlayer: MusicPlayerTrackPreviewPlayer(
                player: MPMusicPlayerController.applicationQueuePlayer
            )
        ),
        systemPlayer: TrackPreviewPlaying = MusicPlayerTrackPreviewPlayer(
            player: MPMusicPlayerController.systemMusicPlayer),
        audioSessionConfigurator: PreviewAudioSessionConfiguring =
            SystemPreviewAudioSessionConfigurator(),
        // A short delay lets SwiftUI start the finger-up dismissal animation before
        // MediaPlayer/audio-session cleanup runs on the main actor.
        stopCleanupDelayNanoseconds: UInt64 = 24_000_000
    ) {
        self.mode = mode
        self.previewPlayer = previewPlayer
        self.systemPlayer = systemPlayer
        self.audioSessionConfigurator = audioSessionConfigurator
        self.stopCleanupDelayNanoseconds = stopCleanupDelayNanoseconds
    }

    deinit {
        progressTask?.cancel()
        delayedResumeTask?.cancel()
        stopCleanupTask?.cancel()
    }

    func startPreview(item: MPMediaItem) {
        let artworkImage = item.artwork?.image(at: CGSize(width: 54, height: 54))
        previewingItem = item
        previewArtworkImage = artworkImage
        startPreview(
            itemID: item.persistentID,
            items: [item],
            duration: item.playbackDuration
        )
        if previewingItemID != item.persistentID {
            previewingItem = nil
            previewArtworkImage = nil
        }
    }

    func startPreview(
        itemID: MPMediaEntityPersistentID,
        items: [MPMediaItem],
        duration: TimeInterval = 0
    ) {
        guard previewingItemID != itemID else { return }

        stopCleanupTask?.cancel()
        stopCleanupTask = nil
        delayedResumeTask?.cancel()
        delayedResumeTask = nil

        let wasPreviewing = previewingItemID != nil
        let shouldResumeAfterPreviousPreview = shouldResumeSystemAfterPreview
        let shouldNotifyAfterPreviousPreview = shouldNotifyOthersAfterPreview

        if wasPreviewing {
            stopCurrentPreview(resumeSystem: false)
        }

        let wasSystemPlaying = systemPlayer.playbackState == .playing
        let wasOtherAudioPlaying = audioSessionConfigurator.isOtherAudioPlaying
        let shouldPauseSystem = mode == .pauseSystem && wasSystemPlaying
        shouldResumeSystemAfterPreview =
            shouldResumeAfterPreviousPreview || wasSystemPlaying
        shouldNotifyOthersAfterPreview =
            shouldNotifyAfterPreviousPreview || wasOtherAudioPlaying

        if shouldPauseSystem {
            systemPlayer.pause()
        }

        do {
            try audioSessionConfigurator.activateForPreview(
                ducksOtherAudio: mode == .independent)
        } catch {
            // Keep preview isolated from the Music app queue even if session setup fails.
        }

        guard previewPlayer.setQueue(with: items) else {
            do {
                try audioSessionConfigurator.deactivatePreview()
            } catch {
                // No preview route is available; leave the app in a non-previewing state.
            }
            resumeInterruptedPlayback(
                shouldResumeSystem: shouldResumeSystemAfterPreview,
                shouldNotifyOthers: shouldNotifyOthersAfterPreview
            )
            shouldResumeSystemAfterPreview = false
            shouldNotifyOthersAfterPreview = false
            return
        }
        previewPlayer.play()
        previewingItemID = itemID
        previewDuration = max(0, duration)
        previewElapsedTime = previewPlayer.currentPlaybackTime
        previewProgress.update(
            elapsedTime: previewElapsedTime,
            duration: previewDuration
        )
        startProgressUpdates()
    }

    func seekPreview(to time: TimeInterval) {
        guard previewingItemID != nil else { return }

        let clampedTime: TimeInterval
        if previewDuration > 0 {
            clampedTime = min(max(0, time), previewDuration)
        } else {
            clampedTime = max(0, time)
        }
        previewPlayer.currentPlaybackTime = clampedTime
        previewPlayer.play()
        previewElapsedTime = clampedTime
        previewProgress.updateElapsedTime(clampedTime)
    }

    func seekPreview(by offset: TimeInterval) {
        seekPreview(to: previewElapsedTime + offset)
    }

    func seekPreview(toFraction fraction: CGFloat) {
        guard previewDuration > 0 else { return }
        let clampedFraction = min(max(0, fraction), 1)
        seekPreview(to: previewDuration * TimeInterval(clampedFraction))
    }

    func updateTouchLocation(_ location: CGPoint) {
        previewTouchLocation = location
    }

    func stopPreview() {
        stopCurrentPreview(resumeSystem: true)
    }

    private func stopCurrentPreview(resumeSystem: Bool) {
        guard previewingItemID != nil else { return }

        progressTask?.cancel()
        progressTask = nil
        // Clear visible preview state immediately; heavier player/session cleanup is
        // scheduled below so the release gesture can return to the UI quickly.
        previewingItemID = nil

        let shouldResumeSystem = shouldResumeSystemAfterPreview
        let shouldNotifyOthers = shouldNotifyOthersAfterPreview

        if resumeSystem {
            scheduleStopCleanup(
                shouldResumeSystem: shouldResumeSystem,
                shouldNotifyOthers: shouldNotifyOthers
            )
        } else {
            previewPlayer.stop()
        }
    }

    private func scheduleStopCleanup(
        shouldResumeSystem: Bool,
        shouldNotifyOthers: Bool
    ) {
        if stopCleanupDelayNanoseconds == 0 {
            finishStopCleanup(
                shouldResumeSystem: shouldResumeSystem,
                shouldNotifyOthers: shouldNotifyOthers
            )
            return
        }

        stopCleanupTask?.cancel()
        let delayNanoseconds = stopCleanupDelayNanoseconds
        stopCleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.finishStopCleanup(
                shouldResumeSystem: shouldResumeSystem,
                shouldNotifyOthers: shouldNotifyOthers
            )
            self.stopCleanupTask = nil
        }
    }

    private func finishStopCleanup(
        shouldResumeSystem: Bool,
        shouldNotifyOthers: Bool
    ) {
        previewPlayer.stop()
        previewingItem = nil
        previewArtworkImage = nil
        previewTouchLocation = nil
        previewElapsedTime = 0
        previewDuration = 0
        previewProgress.reset()
        do {
            try audioSessionConfigurator.deactivatePreview()
        } catch {
            // Playback state restoration is more important than surfacing session errors here.
        }

        resumeInterruptedPlayback(
            shouldResumeSystem: shouldResumeSystem,
            shouldNotifyOthers: shouldNotifyOthers
        )
        shouldResumeSystemAfterPreview = false
        shouldNotifyOthersAfterPreview = false
    }

    private func resumeInterruptedPlayback(
        shouldResumeSystem: Bool,
        shouldNotifyOthers: Bool
    ) {
        if shouldResumeSystem {
            systemPlayer.play()
        }

        let shouldRetrySystemResume = shouldResumeSystem
        let shouldRetryOtherAudioNotification = shouldNotifyOthers
        guard shouldRetrySystemResume || shouldRetryOtherAudioNotification else {
            return
        }

        delayedResumeTask?.cancel()
        delayedResumeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self else { return }
            if shouldRetryOtherAudioNotification {
                try? self.audioSessionConfigurator.deactivatePreview()
            }
            if shouldRetrySystemResume, self.systemPlayer.playbackState != .playing {
                self.systemPlayer.play()
            }
            self.delayedResumeTask = nil
        }
    }

    private func startProgressUpdates() {
        progressTask?.cancel()
        progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.previewingItemID != nil else { return }
                self.previewElapsedTime = self.previewPlayer.currentPlaybackTime
                self.previewProgress.updateElapsedTime(self.previewElapsedTime)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
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
    private let songsCollectionsLoader: SongsCollectionsLoading
    private var songsCollectionsListViewModels: [CollectionTypes: SongsCollectionsListViewModel] =
        [:]
    private var isGeneratingPlaybackNotifications = false

    init(
        playbackNotificationManager: PlaybackNotificationManaging =
            SystemPlaybackNotificationManager(),
        quickDigLoader: QuickDigLoading = SystemQuickDigLoader(),
        songsCollectionsLoader: SongsCollectionsLoading = MediaLibrarySongsCollectionsLoader()
    ) {
        self.playbackNotificationManager = playbackNotificationManager
        self.quickDigLoader = quickDigLoader
        self.songsCollectionsLoader = songsCollectionsLoader
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

    func songsCollectionsListViewModel(
        for type: CollectionTypes
    ) -> SongsCollectionsListViewModel {
        if let viewModel = songsCollectionsListViewModels[type] {
            return viewModel
        }

        let viewModel = SongsCollectionsListViewModel(
            type: type,
            loader: songsCollectionsLoader
        )
        songsCollectionsListViewModels[type] = viewModel
        return viewModel
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
        await refreshNowPlayingSong(showLoading: false)
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) async {
        guard newPhase == .active else { return }
        await refreshNowPlayingSong(showLoading: nowPlayingItem == nil)
    }

    func refreshNowPlayingSong(showLoading: Bool = true) async {
        if showLoading || nowPlayingItem == nil {
            loadingState = .loading
        }
        nowPlayingItem = await nowPlayingLoader.loadNowPlayingSong()
        loadingState = .loaded
    }
}
