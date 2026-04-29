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
