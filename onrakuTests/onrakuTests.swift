//
//  onrakuTests.swift
//  onrakuTests
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI
import XCTest

@testable import onraku

private final class FakePlaybackNotificationManager:
  PlaybackNotificationManaging
{
  private(set) var beginCallCount = 0
  private(set) var endCallCount = 0

  func beginGeneratingPlaybackNotifications() {
    beginCallCount += 1
  }

  func endGeneratingPlaybackNotifications() {
    endCallCount += 1
  }
}

private final class FakeQuickDigLoader: QuickDigLoading {
  private(set) var loadCallCount = 0
  var result: QuickDigData?
  var queuedResults: [QuickDigData?] = []

  func loadQuickDig() async -> QuickDigData? {
    loadCallCount += 1
    if !queuedResults.isEmpty {
      return queuedResults.removeFirst()
    }
    return result
  }
}

private final class FakeNowPlayingLoader: NowPlayingLoading {
  private(set) var loadCallCount = 0
  var result: MPMediaItem?

  func loadNowPlayingSong() async -> MPMediaItem? {
    loadCallCount += 1
    return result
  }
}

private final class FakeDiggingLoader: DiggingLoading {
  private(set) var requestedIdentifiers: [String] = []
  private(set) var requestedDepths: [Int] = []
  var result = DiggingLoadResult(songs: [], predicates: [])
  var queuedResults: [DiggingLoadResult] = []

  func loadDiggingItems(for song: SongDetailLike, withDepth depth: Int) async
    -> DiggingLoadResult
  {
    requestedIdentifiers.append(song.refreshingIdentifier)
    requestedDepths.append(depth)
    if !queuedResults.isEmpty {
      return queuedResults.removeFirst()
    }
    return result
  }
}

private final class FakeSongPlaylistLoader: SongPlaylistLoading {
  private(set) var requestedIdentifiers: [String] = []
  var result: [SongsCollection] = []
  var queuedResults: [[SongsCollection]] = []

  func loadPlaylists(for song: SongDetailLike) async -> [SongsCollection] {
    requestedIdentifiers.append(song.refreshingIdentifier)
    if !queuedResults.isEmpty {
      return queuedResults.removeFirst()
    }
    return result
  }
}

private final class FakeSongsCollectionsLoader: SongsCollectionsLoading {
  private(set) var requestedTypes: [CollectionTypes] = []
  var result: [SongsCollection] = []
  var queuedResults: [[SongsCollection]] = []

  func loadCollections(of type: CollectionTypes) async -> [SongsCollection] {
    requestedTypes.append(type)
    if !queuedResults.isEmpty {
      return queuedResults.removeFirst()
    }
    return result
  }
}

private struct FakeSongsList: SongsList {
  let title: String
  let searchCriteria: [MyMPMediaPropertyPredicate]
  let loader: () async -> [MPMediaItem]

  func loadSongs() async -> [MPMediaItem] {
    await loader()
  }
}

private func makeDummySong(
  refreshingIdentifier: String,
  title: String = "Song"
) -> DummySongDetail {
  DummySongDetail(
    albumArtist: nil,
    albumTitle: nil,
    albumTrackCount: 0,
    albumTrackNumber: 0,
    artist: nil,
    artwork: nil,
    beatsPerMinute: 0,
    comments: nil,
    isCompilation: false,
    composer: nil,
    dateAdded: .now,
    discCount: 0,
    discNumber: 0,
    genre: nil,
    lastPlayedDate: nil,
    lyrics: nil,
    playCount: 0,
    rating: 0,
    releaseDate: nil,
    releaseYear: nil,
    skipCount: 0,
    title: title,
    userGrouping: nil,
    playbackDuration: 0,
    refreshingIdentifier: refreshingIdentifier
  )
}

class onrakuTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testSplit() throws {
    let cases: [(src: String, expected: [String])] = [
      (src: "hoge", expected: []),
      (src: "hoge _piyo Remix_", expected: []),
      (src: "hoge -ababa Remix-", expected: ["ababa"]),
      (src: "hoge - obobo Remix -", expected: ["obobo"]),
      (src: "hoge (fuga Remix)", expected: ["fuga"]),
      (src: "hoge (fuga2 remix)", expected: ["fuga2"]),
      (src: "hoge [foo Remix]", expected: ["foo"]),
      (src: "hoge (DJ Nantoka Remix)", expected: ["DJ Nantoka"]),
      (src: "hoge (DJ Untara Bootleg)", expected: ["DJ Untara"]),
      (src: "hoge (bar Flip)", expected: ["bar"]),
    ]
    cases.forEach { (src, expected) in
      XCTAssertEqual(src.intelligentlyExtractRemixersCredit(), expected)
    }

    let cases2: [(src: String, expected: [String])] = [
      (src: "hoge", expected: []),
      (src: "hoge feat. pi yo", expected: ["pi yo"]),
      (src: "hoge ft. bar", expected: ["bar"]),
      (src: "hoge featuring ababa", expected: ["ababa"]),
      (src: "hoge feat.  obobo", expected: ["obobo"]),
      (src: "hoge feat. fuga (piyo remix)", expected: ["fuga"]),
      (src: "hoge feat. fuga2 [piyo remix]", expected: ["fuga2"]),
      (src: "hoge Prod. foo [piyo remix]", expected: ["foo"]),
    ]
    cases2.forEach { (src, expected) in
      XCTAssertEqual(src.intelligentlyExtractFeaturedArtists(), expected)
    }

    XCTAssertEqual("".intelligentlySplitIntoSubArtists(), [])
    XCTAssertEqual(
      "hoge (aa)".intelligentlySplitIntoSubArtists(), ["hoge", "aa"])
    XCTAssertEqual(
      "a (b), c (d)".intelligentlySplitIntoSubArtists(), ["a", "b", "c", "d"])
    XCTAssertEqual("a & b".intelligentlySplitIntoSubArtists(), ["a", "b"])
    XCTAssertEqual(
      "a (b), c (d) from x".intelligentlySplitIntoSubArtists(),
      ["a", "b", "c", "d", "x"])
    XCTAssertEqual(
      "a・b・c from x".intelligentlySplitIntoSubArtists(), ["a", "b", "c", "x"])
    XCTAssertEqual(
      "foo (a, b, c)".intelligentlySplitIntoSubArtists(),
      ["foo", "a", "b", "c"])
    XCTAssertEqual(
      "foo (a), bar (a)".intelligentlySplitIntoSubArtists(),
      ["foo", "a", "bar"])
    XCTAssertEqual("a x b".intelligentlySplitIntoSubArtists(), ["a", "b"])
    XCTAssertEqual("a × b".intelligentlySplitIntoSubArtists(), ["a", "b"])
    XCTAssertEqual(
      "a feat. b, c".intelligentlySplitIntoSubArtists(), ["a", "b", "c"])
    XCTAssertEqual(
      "a Feat. b, c".intelligentlySplitIntoSubArtists(), ["a", "b", "c"])
    XCTAssertEqual("afeat. b".intelligentlySplitIntoSubArtists(), ["afeat. b"])

    XCTAssertEqual("".intelligentlySplitIntoSubGenres(), [])
    XCTAssertEqual(
      "a / b / c".intelligentlySplitIntoSubGenres(), ["a", "b", "c"])
    XCTAssertEqual(
      "hoge (fuga)".intelligentlySplitIntoSubGenres(), ["hoge", "fuga"])
    XCTAssertEqual(
      "hoge (fuga / piyo)".intelligentlySplitIntoSubGenres(),
      ["hoge", "fuga", "piyo"])
  }

  func testSequenceUniquePreservesFirstOccurrenceOrder() throws {
    XCTAssertEqual([1, 2, 1, 3, 2, 4].unique(), [1, 2, 3, 4])
    XCTAssertEqual(["a", "b", "a", "c", "b"].unique(), ["a", "b", "c"])
  }

  func testArraySliceHelpersReturnExpectedRanges() throws {
    XCTAssertEqual([1, 2, 3, 4].thisAndAbove(at: 2), [1, 2, 3])
    XCTAssertEqual([1, 2, 3, 4].thisAndBelow(at: 1), [2, 3, 4])
  }

  func testLoadingStateIsLoadingOnlyForLoadingCase() throws {
    XCTAssertFalse(LoadingState.initial.isLoading)
    XCTAssertTrue(LoadingState.loading.isLoading)
    XCTAssertFalse(LoadingState.loaded.isLoading)
    XCTAssertFalse(LoadingState.loadingByPullToRefresh.isLoading)
  }

  func testSongsSortKeyRawValuesRemainStable() throws {
    XCTAssertEqual(SongsSortKey.none.rawValue, "Default")
    XCTAssertEqual(SongsSortKey.playCountDesc.rawValue, "Most Played")
    XCTAssertEqual(SongsSortKey.playCountPerDayAsc.rawValue, "Least Frequently Played")
    XCTAssertEqual(SongsSortKey.allCases.count, 12)
  }

  func testPredicateFriendlyLabelFallsBackInPriorityOrder() throws {
    let custom = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist,
      friendryLabel: "Custom Label"
    )
    XCTAssertEqual(custom.someFriendlyLabel, "Custom Label")

    let stringValue = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist
    )
    XCTAssertEqual(
      stringValue.someFriendlyLabel,
      "\(MPMediaItemPropertyArtist): Artist A"
    )

    let unknown = MyMPMediaPropertyPredicate(
      value: nil,
      forProperty: MPMediaItemPropertyArtist
    )
    XCTAssertEqual(unknown.someFriendlyLabel, "<unknown>")
  }

  func testPredicateIdentityDependsOnValuePropertyAndComparisonType() throws {
    let base = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist
    )
    let same = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist
    )
    let differentComparison = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist,
      comparisonType: .contains
    )
    let numeric = MyMPMediaPropertyPredicate(
      value: UInt64(42),
      forProperty: MPMediaItemPropertyAlbumPersistentID
    )

    XCTAssertEqual(base, same)
    XCTAssertNotEqual(base, differentComparison)
    XCTAssertFalse(numeric.id.isEmpty)
  }

  func testPredicatePropertyMetadataMatchesExpectedLabels() throws {
    XCTAssertEqual(
      MyMPMediaPropertyPredicate(
        value: "Album",
        forProperty: MPMediaItemPropertyAlbumTitle
      ).humanReadableForProperty,
      "Album"
    )
    XCTAssertEqual(
      MyMPMediaPropertyPredicate(
        value: "Album",
        forProperty: MPMediaItemPropertyAlbumTitle
      ).systemImageNameForProperty,
      "square.stack"
    )
    XCTAssertEqual(
      MyMPMediaPropertyPredicate(
        value: "Unknown",
        forProperty: "custom.property"
      ).humanReadableForProperty,
      "custom.property"
    )
    XCTAssertNil(
      MyMPMediaPropertyPredicate(
        value: "Unknown",
        forProperty: "custom.property"
      ).systemImageNameForProperty
    )
  }

  func testGenrePredicateExpandsIntoContainsSearchHints() throws {
    let predicate = MyMPMediaPropertyPredicate(
      value: "House / Disco",
      forProperty: MPMediaItemPropertyGenre
    )

    let hints = predicate.getNextSearchHintPredicates()

    XCTAssertEqual(hints.compactMap { $0.value as? String }, ["House", "Disco"])
    XCTAssertTrue(hints.allSatisfy { $0.forProperty == MPMediaItemPropertyGenre })
    XCTAssertTrue(hints.allSatisfy { $0.comparisonType == .contains })
  }

  func testArtistPredicateExpandsIntoArtistTitleAndComposerHints() throws {
    let predicate = MyMPMediaPropertyPredicate(
      value: "Lead Artist feat. Guest One",
      forProperty: MPMediaItemPropertyArtist
    )

    let hints = predicate.getNextSearchHintPredicates()

    XCTAssertEqual(
      hints.filter { $0.forProperty == MPMediaItemPropertyArtist }.count,
      2
    )
    XCTAssertEqual(
      hints.filter { $0.forProperty == MPMediaItemPropertyTitle }.count,
      2
    )
    XCTAssertEqual(
      hints.filter { $0.forProperty == MPMediaItemPropertyComposer }.count,
      2
    )
  }

  func testComposerPredicateExpandsIntoComposerAndArtistHints() throws {
    let predicate = MyMPMediaPropertyPredicate(
      value: "Alpha & Beta",
      forProperty: MPMediaItemPropertyComposer
    )

    let hints = predicate.getNextSearchHintPredicates()

    XCTAssertEqual(
      hints.filter { $0.forProperty == MPMediaItemPropertyComposer }.count,
      2
    )
    XCTAssertEqual(
      hints.filter { $0.forProperty == MPMediaItemPropertyArtist }.count,
      2
    )
  }

  func testCollectionTypesExposeExpectedMetadata() throws {
    XCTAssertEqual(CollectionTypes.playlist.systemImageName, "list.dash")
    XCTAssertEqual(CollectionTypes.album.systemImageName, "square.stack")
    XCTAssertEqual(CollectionTypes.artist.queryPredicateType, MPMediaItemPropertyArtist)
    XCTAssertEqual(CollectionTypes.genre.queryPredicateType, MPMediaItemPropertyGenre)
    XCTAssertEqual(
      CollectionTypes.userGrouping.queryPredicateType,
      MPMediaItemPropertyUserGrouping
    )
  }

  func testSongsCollectionBuildsFilterPredicateFromTypeMetadata() throws {
    let collection = SongsCollection(
      name: "Playlist A",
      id: "playlist-a",
      type: .playlist,
      items: nil
    )

    let predicate = try XCTUnwrap(collection.getFilterPredicate())

    XCTAssertEqual(predicate.value as? String, "Playlist A")
    XCTAssertEqual(predicate.forProperty, MPMediaPlaylistPropertyName)
    XCTAssertEqual(predicate.comparisonType, .equalTo)
  }

  @MainActor
  func testSongsListFixedExposesStaticContract() async throws {
    let sut = SongsListFixed(fixedSongs: [], title: "Fixed")

    XCTAssertEqual(sut.title, "Fixed")
    XCTAssertEqual(sut.searchCriteria, [])
    XCTAssertFalse(sut.shouldShowSearchCriteria)
    XCTAssertEqual(await sut.loadSongs().count, 0)
  }

  @MainActor
  func testSongsListLoadedExposesPredicatesAndLoadedSongsContract() async throws {
    let predicates = [
      MyMPMediaPropertyPredicate(
        value: "Artist A",
        forProperty: MPMediaItemPropertyArtist
      ),
      MyMPMediaPropertyPredicate(
        value: "Genre A",
        forProperty: MPMediaItemPropertyGenre
      ),
    ]
    let sut = SongsListLoaded(loadedSongs: [], title: "Loaded", predicates: predicates)

    XCTAssertEqual(sut.title, "Loaded")
    XCTAssertEqual(sut.searchCriteria, predicates)
    XCTAssertTrue(sut.shouldShowSearchCriteria)
    XCTAssertEqual(await sut.loadSongs().count, 0)
  }

  func testSongsListFromPredicatesUsesCustomAndDefaultTitles() throws {
    let predicate = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist
    )

    let defaultTitle = SongsListFromPredicates(predicates: [predicate], customTitle: nil)
    let customTitle = SongsListFromPredicates(
      predicates: [predicate, predicate],
      customTitle: "Custom"
    )

    XCTAssertEqual(defaultTitle.title, "Search Result")
    XCTAssertFalse(defaultTitle.shouldShowSearchCriteria)
    XCTAssertEqual(customTitle.title, "Custom")
    XCTAssertTrue(customTitle.shouldShowSearchCriteria)
  }

  @MainActor
  func testGetSongsByPredicatesReturnsEmptyForNoPredicates() async throws {
    let songs = await getSongsByPredicates([])
    XCTAssertTrue(songs.isEmpty)
  }

  @MainActor
  func testQueriedSongsListViewModelLoadsOnlyOnceUntilReloaded() async throws {
    var loadCount = 0
    let sut = QueriedSongsListViewModel(
      title: "Search Result",
      searchCriteria: []
    ) {
      loadCount += 1
      return []
    }

    XCTAssertEqual(sut.loadingState, .initial)
    XCTAssertTrue(sut.songs.isEmpty)

    await sut.loadIfNeeded()
    XCTAssertEqual(loadCount, 1)
    XCTAssertEqual(sut.loadingState, .loaded)

    await sut.loadIfNeeded()
    XCTAssertEqual(loadCount, 1)

    await sut.reload()
    XCTAssertEqual(loadCount, 2)
    XCTAssertEqual(sut.loadingState, .loaded)
  }

  @MainActor
  func testQueriedSongsListViewModelInitializesFromSongsListContract() async throws {
    var loadCount = 0
    let songsList = FakeSongsList(
      title: "Injected",
      searchCriteria: [
        MyMPMediaPropertyPredicate(
          value: "Artist A",
          forProperty: MPMediaItemPropertyArtist
        ),
        MyMPMediaPropertyPredicate(
          value: "Genre A",
          forProperty: MPMediaItemPropertyGenre
        ),
      ],
      loader: {
        loadCount += 1
        return []
      }
    )
    let sut = QueriedSongsListViewModel(songsList: songsList)

    XCTAssertEqual(sut.title, "Injected")
    XCTAssertEqual(sut.searchCriteria.count, 2)
    XCTAssertTrue(sut.shouldShowSearchCriteria)

    await sut.loadIfNeeded()
    XCTAssertEqual(loadCount, 1)
  }

  @MainActor
  func testQueriedSongsListViewModelExposesSearchCriteriaState() async throws {
    let predicates = [
      MyMPMediaPropertyPredicate(
        value: "Artist A",
        forProperty: MPMediaItemPropertyArtist
      ),
      MyMPMediaPropertyPredicate(
        value: "Genre A",
        forProperty: MPMediaItemPropertyGenre
      ),
    ]
    let sut = QueriedSongsListViewModel(
      title: "Search Result",
      searchCriteria: predicates
    ) {
      []
    }

    XCTAssertEqual(sut.searchCriteria, predicates)
    XCTAssertTrue(sut.shouldShowSearchCriteria)
  }

  @MainActor
  func testQueriedSongsListViewModelDoesNotShowSingleSearchCriterion() async throws {
    let sut = QueriedSongsListViewModel(
      title: "Search Result",
      searchCriteria: [
        MyMPMediaPropertyPredicate(
          value: "Artist A",
          forProperty: MPMediaItemPropertyArtist
        )
      ]
    ) {
      []
    }

    XCTAssertFalse(sut.shouldShowSearchCriteria)
  }

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

  //    func testPerformanceExample() throws {
  //        // This is an example of a performance test case.
  //        self.measure {
  //            // Put the code you want to measure the time of here.
  //        }
  //    }

}
