import MediaPlayer
import SwiftUI
import XCTest

@testable import onraku

final class ViewModelTests: XCTestCase {

  @MainActor
  func testContentViewModelStartsAndStopsPlaybackNotificationsOnlyOnce() async throws {
    let playbackNotificationManager = FakePlaybackNotificationManager()
    let quickDigLoader = FakeQuickDigLoader()
    let sut = ContentViewModel(
      playbackNotificationManager: playbackNotificationManager,
      quickDigLoader: quickDigLoader
    )

    sut.onAppear()
    sut.onAppear()
    XCTAssertEqual(playbackNotificationManager.beginCallCount, 1)

    sut.onDisappear()
    sut.onDisappear()
    XCTAssertEqual(playbackNotificationManager.endCallCount, 1)
  }

  @MainActor
  func testContentViewModelRefreshesQuickDigWhenActivated() async throws {
    let playbackNotificationManager = FakePlaybackNotificationManager()
    let quickDigLoader = FakeQuickDigLoader()
    let sut = ContentViewModel(
      playbackNotificationManager: playbackNotificationManager,
      quickDigLoader: quickDigLoader
    )

    await sut.handleScenePhaseChange(.active)

    XCTAssertEqual(playbackNotificationManager.beginCallCount, 1)
    XCTAssertEqual(quickDigLoader.loadCallCount, 1)
  }

  @MainActor
  func testContentViewModelStopsNotificationsOutsideActiveScene() async throws {
    let playbackNotificationManager = FakePlaybackNotificationManager()
    let quickDigLoader = FakeQuickDigLoader()
    let sut = ContentViewModel(
      playbackNotificationManager: playbackNotificationManager,
      quickDigLoader: quickDigLoader
    )

    sut.onAppear()
    await sut.handleScenePhaseChange(.background)

    XCTAssertEqual(playbackNotificationManager.beginCallCount, 1)
    XCTAssertEqual(playbackNotificationManager.endCallCount, 1)
    XCTAssertEqual(quickDigLoader.loadCallCount, 0)
  }

  @MainActor
  func testContentViewModelDoesNotStopNotificationsBeforeAppear() async throws {
    let playbackNotificationManager = FakePlaybackNotificationManager()
    let sut = ContentViewModel(
      playbackNotificationManager: playbackNotificationManager,
      quickDigLoader: FakeQuickDigLoader()
    )

    sut.onDisappear()

    XCTAssertEqual(playbackNotificationManager.beginCallCount, 0)
    XCTAssertEqual(playbackNotificationManager.endCallCount, 0)
  }

  @MainActor
  func testContentViewModelActiveSceneAfterAppearDoesNotBeginTwice() async throws {
    let playbackNotificationManager = FakePlaybackNotificationManager()
    let quickDigLoader = FakeQuickDigLoader()
    let sut = ContentViewModel(
      playbackNotificationManager: playbackNotificationManager,
      quickDigLoader: quickDigLoader
    )

    sut.onAppear()
    await sut.handleScenePhaseChange(.active)

    XCTAssertEqual(playbackNotificationManager.beginCallCount, 1)
    XCTAssertEqual(quickDigLoader.loadCallCount, 1)
  }

  @MainActor
  func testContentViewModelUpdatesQuickDigPredicatesFromLoader() async throws {
    let quickDigLoader = FakeQuickDigLoader()
    quickDigLoader.result = QuickDigData(
      songs: [],
      predicates: [
        MyMPMediaPropertyPredicate(
          value: "Genre A",
          forProperty: MPMediaItemPropertyGenre
        )
      ]
    )
    let sut = ContentViewModel(
      playbackNotificationManager: FakePlaybackNotificationManager(),
      quickDigLoader: quickDigLoader
    )

    await sut.handleNowPlayingItemDidChange()

    XCTAssertEqual(sut.quickDigPredicates.count, 1)
    XCTAssertEqual(
      sut.quickDigPredicates.first?.forProperty,
      MPMediaItemPropertyGenre
    )
  }

  @MainActor
  func testContentViewModelKeepsExistingQuickDigWhenLoaderReturnsNil() async throws {
    let quickDigLoader = FakeQuickDigLoader()
    quickDigLoader.queuedResults = [
      QuickDigData(
        songs: [],
        predicates: [
          MyMPMediaPropertyPredicate(
            value: "Genre A",
            forProperty: MPMediaItemPropertyGenre
          )
        ]
      ),
      nil,
    ]
    let sut = ContentViewModel(
      playbackNotificationManager: FakePlaybackNotificationManager(),
      quickDigLoader: quickDigLoader
    )

    await sut.handleNowPlayingItemDidChange()
    await sut.handleNowPlayingItemDidChange()

    XCTAssertEqual(sut.quickDigPredicates.count, 1)
    XCTAssertEqual(quickDigLoader.loadCallCount, 2)
  }

  @MainActor
  func testContentViewModelReusesSongsCollectionsListViewModels() async throws {
    let sut = ContentViewModel(
      playbackNotificationManager: FakePlaybackNotificationManager(),
      quickDigLoader: FakeQuickDigLoader()
    )

    let firstPlaylistViewModel = sut.songsCollectionsListViewModel(for: .playlist)
    let secondPlaylistViewModel = sut.songsCollectionsListViewModel(for: .playlist)
    let albumViewModel = sut.songsCollectionsListViewModel(for: .album)

    XCTAssertTrue(firstPlaylistViewModel === secondPlaylistViewModel)
    XCTAssertFalse(firstPlaylistViewModel === albumViewModel)
  }

  @MainActor
  func testNowPlayingViewModelOnlyRefreshesNotificationWhileAppearing() async throws {
    let nowPlayingLoader = FakeNowPlayingLoader()
    let sut = NowPlayingViewModel(nowPlayingLoader: nowPlayingLoader)

    await sut.handleNowPlayingItemDidChange()
    XCTAssertEqual(nowPlayingLoader.loadCallCount, 0)

    sut.onAppear()
    await sut.handleNowPlayingItemDidChange()
    XCTAssertEqual(nowPlayingLoader.loadCallCount, 1)

    sut.onDisappear()
    await sut.handleNowPlayingItemDidChange()
    XCTAssertEqual(nowPlayingLoader.loadCallCount, 1)
  }

  @MainActor
  func testNowPlayingViewModelRefreshesWhenSceneBecomesActive() async throws {
    let nowPlayingLoader = FakeNowPlayingLoader()
    let sut = NowPlayingViewModel(nowPlayingLoader: nowPlayingLoader)

    await sut.handleScenePhaseChange(.background)
    XCTAssertEqual(nowPlayingLoader.loadCallCount, 0)

    await sut.handleScenePhaseChange(.active)
    XCTAssertEqual(nowPlayingLoader.loadCallCount, 1)
    XCTAssertEqual(sut.loadingState, .loaded)
  }

  @MainActor
  func testNowPlayingViewModelActiveSceneRefreshesEvenWhenNotAppearing() async throws {
    let nowPlayingLoader = FakeNowPlayingLoader()
    let sut = NowPlayingViewModel(nowPlayingLoader: nowPlayingLoader)

    sut.onDisappear()
    await sut.handleScenePhaseChange(.active)

    XCTAssertEqual(nowPlayingLoader.loadCallCount, 1)
  }

  @MainActor
  func testNowPlayingViewModelRefreshableLoadsEvenWithoutAppearance() async throws {
    let nowPlayingLoader = FakeNowPlayingLoader()
    let sut = NowPlayingViewModel(nowPlayingLoader: nowPlayingLoader)

    await sut.refreshNowPlayingSong()

    XCTAssertEqual(nowPlayingLoader.loadCallCount, 1)
    XCTAssertEqual(sut.loadingState, .loaded)
  }

  @MainActor
  func testTrackPreviewControllerIndependentModeRestoresSystemPlaybackWithoutPausing()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .playing)
    let audioSessionConfigurator = FakePreviewAudioSessionConfigurator()
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: audioSessionConfigurator,
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    sut.stopPreview()

    XCTAssertEqual(previewPlayer.queuedItemCounts, [0])
    XCTAssertEqual(previewPlayer.playCallCount, 1)
    XCTAssertEqual(previewPlayer.stopCallCount, 1)
    XCTAssertEqual(systemPlayer.pauseCallCount, 0)
    XCTAssertEqual(systemPlayer.playCallCount, 1)
    XCTAssertEqual(audioSessionConfigurator.activationDuckingValues, [true])
    XCTAssertEqual(audioSessionConfigurator.deactivateCallCount, 1)
  }

  @MainActor
  func testTrackPreviewControllerIndependentModeRestoresInterruptedSystemPlayback()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .playing)
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    systemPlayer.playbackState = .paused
    sut.stopPreview()

    XCTAssertEqual(systemPlayer.pauseCallCount, 0)
    XCTAssertEqual(systemPlayer.playCallCount, 1)
  }

  @MainActor
  func testTrackPreviewControllerNotifiesInterruptedNonMusicAudioAfterPreview()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .paused)
    let audioSessionConfigurator = FakePreviewAudioSessionConfigurator()
    audioSessionConfigurator.isOtherAudioPlaying = true
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: audioSessionConfigurator,
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    sut.stopPreview()

    XCTAssertEqual(systemPlayer.playCallCount, 0)
    XCTAssertEqual(audioSessionConfigurator.deactivateCallCount, 1)

    try await Task.sleep(nanoseconds: 350_000_000)

    XCTAssertEqual(systemPlayer.playCallCount, 0)
    XCTAssertEqual(audioSessionConfigurator.deactivateCallCount, 2)
  }

  func testFallbackTrackPreviewPlayerUsesFallbackWhenPrimaryCannotQueue() {
    let primaryPlayer = FakeTrackPreviewPlayer()
    primaryPlayer.queueSucceeds = false
    let fallbackPlayer = FakeTrackPreviewPlayer()
    let sut = FallbackTrackPreviewPlayer(
      primaryPlayer: primaryPlayer,
      fallbackPlayer: fallbackPlayer
    )

    XCTAssertTrue(sut.setQueue(with: []))
    sut.play()
    sut.currentPlaybackTime = 42
    sut.stop()

    XCTAssertEqual(primaryPlayer.queuedItemCounts, [0])
    XCTAssertEqual(primaryPlayer.playCallCount, 0)
    XCTAssertEqual(primaryPlayer.stopCallCount, 0)
    XCTAssertEqual(fallbackPlayer.queuedItemCounts, [0])
    XCTAssertEqual(fallbackPlayer.playCallCount, 1)
    XCTAssertEqual(fallbackPlayer.currentPlaybackTime, 42)
    XCTAssertEqual(fallbackPlayer.stopCallCount, 1)
  }

  @MainActor
  func testTrackPreviewControllerPauseSystemModeResumesWhenSystemWasPlaying()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .playing)
    let audioSessionConfigurator = FakePreviewAudioSessionConfigurator()
    let sut = TrackPreviewController(
      mode: .pauseSystem,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: audioSessionConfigurator,
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    sut.stopPreview()

    XCTAssertEqual(systemPlayer.pauseCallCount, 1)
    XCTAssertEqual(systemPlayer.playCallCount, 1)
    XCTAssertEqual(previewPlayer.playCallCount, 1)
    XCTAssertEqual(previewPlayer.stopCallCount, 1)
    XCTAssertEqual(audioSessionConfigurator.activationDuckingValues, [false])
  }

  @MainActor
  func testTrackPreviewControllerPauseSystemModeDoesNotResumeStoppedSystem()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .paused)
    let sut = TrackPreviewController(
      mode: .pauseSystem,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    sut.stopPreview()

    XCTAssertEqual(systemPlayer.pauseCallCount, 0)
    XCTAssertEqual(systemPlayer.playCallCount, 0)
    XCTAssertEqual(previewPlayer.stopCallCount, 1)
  }

  @MainActor
  func testTrackPreviewControllerDefersHeavyStopCleanupAfterClearingPreviewState()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .playing)
    let audioSessionConfigurator = FakePreviewAudioSessionConfigurator()
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: audioSessionConfigurator,
      stopCleanupDelayNanoseconds: 1_000_000_000
    )

    sut.startPreview(itemID: 1, items: [])
    sut.stopPreview()

    XCTAssertNil(sut.previewingItemID)
    XCTAssertEqual(previewPlayer.pauseCallCount, 0)
    XCTAssertEqual(previewPlayer.stopCallCount, 0)
    XCTAssertEqual(audioSessionConfigurator.deactivateCallCount, 0)
    XCTAssertEqual(systemPlayer.playCallCount, 0)
  }

  @MainActor
  func testTrackPreviewControllerSwitchesPreviewItemsWithoutResumingBetweenThem()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let systemPlayer = FakeTrackPreviewPlayer(playbackState: .playing)
    let sut = TrackPreviewController(
      mode: .pauseSystem,
      previewPlayer: previewPlayer,
      systemPlayer: systemPlayer,
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [])
    sut.startPreview(itemID: 2, items: [])

    XCTAssertEqual(sut.previewingItemID, 2)
    XCTAssertEqual(previewPlayer.queuedItemCounts, [0, 0])
    XCTAssertEqual(previewPlayer.stopCallCount, 1)
    XCTAssertEqual(systemPlayer.pauseCallCount, 1)
    XCTAssertEqual(systemPlayer.playCallCount, 0)

    sut.stopPreview()

    XCTAssertNil(sut.previewingItemID)
    XCTAssertEqual(systemPlayer.playCallCount, 1)
  }

  @MainActor
  func testTrackPreviewControllerSeeksAndClampsPreviewPosition() async throws {
    let previewPlayer = FakeTrackPreviewPlayer()
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: FakeTrackPreviewPlayer(),
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [], duration: 95)
    sut.seekPreview(to: 120)

    XCTAssertEqual(previewPlayer.currentPlaybackTime, 95)
    XCTAssertEqual(sut.previewElapsedTime, 95)

    sut.seekPreview(to: -10)

    XCTAssertEqual(previewPlayer.currentPlaybackTime, 0)
    XCTAssertEqual(sut.previewElapsedTime, 0)
  }

  @MainActor
  func testTrackPreviewControllerSeeksByScreenFraction() async throws {
    let previewPlayer = FakeTrackPreviewPlayer()
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: FakeTrackPreviewPlayer(),
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [], duration: 200)
    sut.seekPreview(toFraction: 0.75)

    XCTAssertEqual(previewPlayer.currentPlaybackTime, 150)
    XCTAssertEqual(sut.previewElapsedTime, 150)
  }

  @MainActor
  func testTrackPreviewControllerResumesPreviewPlaybackAfterSeekingBackFromEnd()
    async throws
  {
    let previewPlayer = FakeTrackPreviewPlayer()
    let sut = TrackPreviewController(
      mode: .independent,
      previewPlayer: previewPlayer,
      systemPlayer: FakeTrackPreviewPlayer(),
      audioSessionConfigurator: FakePreviewAudioSessionConfigurator(),
      stopCleanupDelayNanoseconds: 0
    )

    sut.startPreview(itemID: 1, items: [], duration: 200)
    previewPlayer.playbackState = .stopped

    sut.seekPreview(toFraction: 0.5)

    XCTAssertEqual(previewPlayer.currentPlaybackTime, 100)
    XCTAssertEqual(previewPlayer.playCallCount, 2)
  }

  func testTrackPreviewScreenSeekMapperTreatsScreenEdgesAsMargins() throws {
    let screenWidth: CGFloat = 400
    let edgeMargin: CGFloat = 84

    XCTAssertEqual(
      TrackPreviewScreenSeekMapper.fraction(
        forX: 0,
        screenWidth: screenWidth,
        edgeMargin: edgeMargin
      ),
      0
    )
    XCTAssertEqual(
      TrackPreviewScreenSeekMapper.fraction(
        forX: edgeMargin,
        screenWidth: screenWidth,
        edgeMargin: edgeMargin
      ),
      0
    )
    XCTAssertEqual(
      TrackPreviewScreenSeekMapper.fraction(
        forX: screenWidth - edgeMargin,
        screenWidth: screenWidth,
        edgeMargin: edgeMargin
      ),
      1
    )
    XCTAssertEqual(
      TrackPreviewScreenSeekMapper.fraction(
        forX: screenWidth,
        screenWidth: screenWidth,
        edgeMargin: edgeMargin
      ),
      1
    )
    XCTAssertEqual(
      TrackPreviewScreenSeekMapper.fraction(
        forX: screenWidth / 2,
        screenWidth: screenWidth,
        edgeMargin: edgeMargin
      ),
      0.5
    )
  }

  func testTrackPreviewHUDLayoutCentersHUDOnXAxis() throws {
    let size = CGSize(width: 390, height: 700)
    let frame = CGRect(x: 20, y: 40, width: 390, height: 700)

    let leftTouchPosition = TrackPreviewHUDLayout.hudPosition(
      containerSize: size,
      containerGlobalFrame: frame,
      touchLocation: CGPoint(x: frame.minX + 24, y: frame.minY + 260)
    )
    let rightTouchPosition = TrackPreviewHUDLayout.hudPosition(
      containerSize: size,
      containerGlobalFrame: frame,
      touchLocation: CGPoint(x: frame.maxX - 24, y: frame.minY + 260)
    )

    XCTAssertEqual(leftTouchPosition.x, size.width / 2)
    XCTAssertEqual(rightTouchPosition.x, size.width / 2)
  }

  func testTrackPreviewHUDLayoutPlacesHUDAboveOrBelowTouch() throws {
    let size = CGSize(width: 390, height: 700)
    let frame = CGRect(x: 20, y: 40, width: 390, height: 700)

    let upperTouchPosition = TrackPreviewHUDLayout.hudPosition(
      containerSize: size,
      containerGlobalFrame: frame,
      touchLocation: CGPoint(x: frame.midX, y: frame.minY + 120)
    )
    let lowerTouchPosition = TrackPreviewHUDLayout.hudPosition(
      containerSize: size,
      containerGlobalFrame: frame,
      touchLocation: CGPoint(x: frame.midX, y: frame.minY + 260)
    )

    XCTAssertEqual(upperTouchPosition.y, 225)
    XCTAssertEqual(lowerTouchPosition.y, 155)
  }

  func testTrackPreviewHUDLayoutClampsSeekGuideToEffectiveMargins() throws {
    let size = CGSize(width: 400, height: 600)
    let frame = CGRect(x: 10, y: 20, width: 400, height: 600)

    XCTAssertEqual(TrackPreviewHUDLayout.seekGuideWidth(containerWidth: size.width), 232)
    XCTAssertEqual(
      TrackPreviewHUDLayout.seekGuideX(
        containerSize: size,
        containerGlobalFrame: frame,
        touchLocation: CGPoint(x: frame.minX, y: frame.midY)
      ),
      84
    )
    XCTAssertEqual(
      TrackPreviewHUDLayout.seekGuideX(
        containerSize: size,
        containerGlobalFrame: frame,
        touchLocation: CGPoint(x: frame.maxX, y: frame.midY)
      ),
      316
    )
  }

  func testTrackPreviewModeLoadsStoredSettingWithIndependentDefault() throws {
    let suiteName = UUID().uuidString
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }

    XCTAssertEqual(TrackPreviewMode.stored(in: defaults), .independent)

    defaults.set(TrackPreviewMode.pauseSystem.rawValue, forKey: TrackPreviewMode.storageKey)
    XCTAssertEqual(TrackPreviewMode.stored(in: defaults), .pauseSystem)

    defaults.set("unknown", forKey: TrackPreviewMode.storageKey)
    XCTAssertEqual(TrackPreviewMode.stored(in: defaults), .independent)
  }

  @MainActor
  func testDiggingViewModelLoadsOncePerSongIdentifier() async throws {
    let loader = FakeDiggingLoader()
    let sut = DiggingViewModel(loader: loader)
    let song = makeDummySong(refreshingIdentifier: "song-1")

    await sut.load(for: song, withDepth: 2)
    await sut.load(for: song, withDepth: 2)

    XCTAssertEqual(loader.requestedIdentifiers, ["song-1"])
    XCTAssertEqual(loader.requestedDepths, [2])
    XCTAssertEqual(sut.loadingState, .loaded)
  }

  @MainActor
  func testDiggingViewModelBuildsSongsListWithSearchCriteria() async throws {
    let loader = FakeDiggingLoader()
    let predicates = [
      MyMPMediaPropertyPredicate(
        value: "Artist A",
        forProperty: MPMediaItemPropertyArtist
      ),
      MyMPMediaPropertyPredicate(
        value: "Composer A",
        forProperty: MPMediaItemPropertyComposer
      ),
    ]
    loader.result = DiggingLoadResult(songs: [], predicates: predicates)
    let sut = DiggingViewModel(loader: loader)

    await sut.load(for: makeDummySong(refreshingIdentifier: "song-1"), withDepth: 1)

    let songsList = sut.songsList(title: "Dig Deeper")

    XCTAssertEqual(songsList.title, "Dig Deeper")
    XCTAssertEqual(songsList.searchCriteria, predicates)
    XCTAssertTrue(songsList.shouldShowSearchCriteria)
  }

  @MainActor
  func testDiggingViewModelReloadsWhenSongIdentifierChanges() async throws {
    let loader = FakeDiggingLoader()
    loader.queuedResults = [
      DiggingLoadResult(
        songs: [],
        predicates: [
          MyMPMediaPropertyPredicate(
            value: "Genre A",
            forProperty: MPMediaItemPropertyGenre
          )
        ]
      ),
      DiggingLoadResult(songs: [], predicates: []),
    ]
    let sut = DiggingViewModel(loader: loader)

    await sut.load(for: makeDummySong(refreshingIdentifier: "song-1"), withDepth: 1)
    await sut.load(for: makeDummySong(refreshingIdentifier: "song-2"), withDepth: 3)

    XCTAssertEqual(loader.requestedIdentifiers, ["song-1", "song-2"])
    XCTAssertEqual(loader.requestedDepths, [1, 3])
    XCTAssertTrue(sut.predicates.isEmpty)
  }

  @MainActor
  func testPlaylistsBySongViewModelLoadsForDummySong() async throws {
    let loader = FakeSongPlaylistLoader()
    loader.result = [
      SongsCollection(name: "Playlist A", id: "1", type: .playlist, items: nil)
    ]
    let sut = PlaylistsBySongViewModel(loader: loader)
    let song = makeDummySong(refreshingIdentifier: "song-2")

    await sut.load(for: song)

    XCTAssertEqual(loader.requestedIdentifiers, ["song-2"])
    XCTAssertEqual(sut.playlists.count, 1)
    XCTAssertEqual(sut.loadingState, .loaded)
  }

  @MainActor
  func testPlaylistsBySongViewModelReplacesPlaylistsForNewSong() async throws {
    let loader = FakeSongPlaylistLoader()
    loader.queuedResults = [
      [SongsCollection(name: "Playlist A", id: "1", type: .playlist, items: nil)],
      [],
    ]
    let sut = PlaylistsBySongViewModel(loader: loader)

    await sut.load(for: makeDummySong(refreshingIdentifier: "song-1"))
    XCTAssertEqual(sut.playlists.count, 1)

    await sut.load(for: makeDummySong(refreshingIdentifier: "song-2"))
    XCTAssertTrue(sut.playlists.isEmpty)
    XCTAssertEqual(loader.requestedIdentifiers, ["song-1", "song-2"])
  }

  @MainActor
  func testPlaylistsBySongViewModelSkipsRepeatedSongIdentifier() async throws {
    let loader = FakeSongPlaylistLoader()
    let sut = PlaylistsBySongViewModel(loader: loader)
    let song = makeDummySong(refreshingIdentifier: "song-2")

    await sut.load(for: song)
    await sut.load(for: song)

    XCTAssertEqual(loader.requestedIdentifiers, ["song-2"])
  }

  @MainActor
  func testSongsCollectionsListViewModelLoadsOnlyOnceUntilReloaded() async throws {
    let loader = FakeSongsCollectionsLoader()
    loader.result = [
      SongsCollection(name: "Playlist A", id: "1", type: .playlist, items: nil)
    ]
    let sut = SongsCollectionsListViewModel(type: .playlist, loader: loader)

    await sut.loadIfNeeded()
    await sut.loadIfNeeded()

    XCTAssertEqual(loader.requestedTypes, [.playlist])
    XCTAssertEqual(sut.collections.count, 1)
    XCTAssertEqual(sut.loadState, .loaded)

    await sut.reload()
    XCTAssertEqual(loader.requestedTypes, [.playlist, .playlist])
  }

  @MainActor
  func testSongsCollectionsListViewModelLoadsEmptyResults() async throws {
    let loader = FakeSongsCollectionsLoader()
    loader.result = []
    let sut = SongsCollectionsListViewModel(type: .genre, loader: loader)

    await sut.loadIfNeeded()

    XCTAssertEqual(loader.requestedTypes, [.genre])
    XCTAssertTrue(sut.collections.isEmpty)
    XCTAssertEqual(sut.loadState, .loaded)
  }

  @MainActor
  func testSongsCollectionsListViewModelReloadReplacesCollections() async throws {
    let loader = FakeSongsCollectionsLoader()
    loader.queuedResults = [
      [SongsCollection(name: "Playlist A", id: "1", type: .playlist, items: nil)],
      [SongsCollection(name: "Playlist B", id: "2", type: .playlist, items: nil)],
    ]
    let sut = SongsCollectionsListViewModel(type: .playlist, loader: loader)

    await sut.loadIfNeeded()
    XCTAssertEqual(sut.collections.map(\.name), ["Playlist A"])

    await sut.reload()
    XCTAssertEqual(sut.collections.map(\.name), ["Playlist B"])
  }

  @MainActor
  func testSongsCollectionsListViewModelReloadKeepsExpandedFoldersThatStillExist()
    async throws
  {
    let loader = FakeSongsCollectionsLoader()
    loader.queuedResults = [
      [
        SongsCollection(
          name: "Folder A",
          id: "folder-a",
          type: .playlist,
          items: nil,
          isFolder: true
        ),
        SongsCollection(
          name: "Playlist A",
          id: "playlist-a",
          type: .playlist,
          items: nil,
          parentID: "folder-a"
        ),
      ],
      [
        SongsCollection(
          name: "Folder A",
          id: "folder-a",
          type: .playlist,
          items: nil,
          isFolder: true
        ),
        SongsCollection(
          name: "Playlist B",
          id: "playlist-b",
          type: .playlist,
          items: nil,
          parentID: "folder-a"
        ),
      ],
    ]
    let sut = SongsCollectionsListViewModel(type: .playlist, loader: loader)

    await sut.loadIfNeeded()
    sut.toggleExpansion(of: "folder-a")

    await sut.reload()

    XCTAssertEqual(sut.expandedCollectionIDs, ["folder-a"])
    XCTAssertEqual(
      sut.visibleCollectionRows.map { $0.node.collection.name },
      ["Folder A", "Playlist B"]
    )
  }

  @MainActor
  func testSongsCollectionsListViewModelShowsCollapsedPlaylistTreeRowsUntilToggled()
    async throws
  {
    let loader = FakeSongsCollectionsLoader()
    loader.result = [
      SongsCollection(
        name: "Folder A",
        id: "folder-a",
        type: .playlist,
        items: nil,
        isFolder: true
      ),
      SongsCollection(
        name: "Playlist A",
        id: "playlist-a",
        type: .playlist,
        items: nil,
        parentID: "folder-a"
      ),
      SongsCollection(
        name: "Playlist B",
        id: "playlist-b",
        type: .playlist,
        items: nil
      ),
    ]
    let sut = SongsCollectionsListViewModel(type: .playlist, loader: loader)

    await sut.loadIfNeeded()

    XCTAssertEqual(
      sut.visibleCollectionRows.map { $0.node.collection.name },
      ["Folder A", "Playlist B"]
    )
    XCTAssertEqual(sut.visibleCollectionRows.map(\.depth), [0, 0])
    XCTAssertEqual(sut.visibleCollectionRows.map(\.hasChildren), [true, false])

    sut.toggleExpansion(of: "folder-a")

    XCTAssertEqual(
      sut.visibleCollectionRows.map { $0.node.collection.name },
      ["Folder A", "Playlist A", "Playlist B"]
    )
    XCTAssertEqual(sut.visibleCollectionRows.map(\.depth), [0, 1, 0])
  }
}
