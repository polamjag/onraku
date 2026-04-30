import MediaPlayer
import XCTest

@testable import onraku

final class CoreModelTests: XCTestCase {

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

  func testSongsSortKeyBuildsTertiaryInfoForSongRows() throws {
    let song = DummySongDetail(
      albumArtist: nil,
      albumTitle: "Album A",
      albumTrackCount: 0,
      albumTrackNumber: 0,
      artist: "Artist A",
      artwork: nil,
      beatsPerMinute: 124,
      comments: nil,
      isCompilation: false,
      composer: nil,
      dateAdded: Date(timeIntervalSince1970: 1_700_000_000),
      discCount: 0,
      discNumber: 0,
      genre: "House",
      lastPlayedDate: nil,
      lyrics: nil,
      playCount: 7,
      rating: 0,
      releaseDate: nil,
      releaseYear: nil,
      skipCount: 0,
      title: "Song A",
      userGrouping: "Peak",
      playbackDuration: 0,
      refreshingIdentifier: "song-1"
    )

    XCTAssertNil(SongsSortKey.none.tertiaryInfo(for: song))
    XCTAssertEqual(SongsSortKey.album.tertiaryInfo(for: song), "Album A")
    XCTAssertEqual(SongsSortKey.genre.tertiaryInfo(for: song), "House")
    XCTAssertEqual(SongsSortKey.userGrouping.tertiaryInfo(for: song), "Peak")
    XCTAssertEqual(SongsSortKey.bpm.tertiaryInfo(for: song), "124")
    XCTAssertEqual(SongsSortKey.playCountDesc.tertiaryInfo(for: song), "7 plays")
  }

  func testPredicateFriendlyLabelFallsBackInPriorityOrder() throws {
    let custom = MyMPMediaPropertyPredicate(
      value: "Artist A",
      forProperty: MPMediaItemPropertyArtist,
      friendlyLabel: "Custom Label"
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

  func testSongScopedLoadTrackerSkipsRepeatedSongIdentifiers() throws {
    var sut = SongScopedLoadTracker()
    let first = makeDummySong(refreshingIdentifier: "song-1")
    let repeated = makeDummySong(refreshingIdentifier: "song-1")
    let next = makeDummySong(refreshingIdentifier: "song-2")

    XCTAssertEqual(sut.beginLoad(for: first), "song-1")
    XCTAssertNil(sut.beginLoad(for: repeated))
    XCTAssertEqual(sut.beginLoad(for: next), "song-2")
  }

  func testSongScopedLoadTrackerMatchesOnlyCurrentLoad() throws {
    var sut = SongScopedLoadTracker()

    _ = sut.beginLoad(for: makeDummySong(refreshingIdentifier: "song-1"))
    XCTAssertTrue(sut.matchesCurrentLoad("song-1"))

    _ = sut.beginLoad(for: makeDummySong(refreshingIdentifier: "song-2"))
    XCTAssertFalse(sut.matchesCurrentLoad("song-1"))
    XCTAssertTrue(sut.matchesCurrentLoad("song-2"))
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

  func testSongsCollectionBuildsSongsListWithoutOptionalPredicate() throws {
    let collection = SongsCollection(
      name: "Genre A",
      id: "genre-a",
      type: .genre,
      items: nil
    )

    let songsList = collection.songsList()

    XCTAssertEqual(songsList.title, "Genre A")
    XCTAssertEqual(songsList.searchCriteria.count, 1)
    XCTAssertEqual(
      songsList.searchCriteria.first?.forProperty,
      MPMediaItemPropertyGenre
    )
  }

  func testPlaylistCollectionBuildsSongsListWithoutVisibleSearchCriteria() throws {
    let collection = SongsCollection(
      name: "Playlist A",
      id: "playlist-a",
      type: .playlist,
      items: nil
    )

    let songsList = collection.songsList()

    XCTAssertEqual(songsList.title, "Playlist A")
    XCTAssertTrue(songsList.searchCriteria.isEmpty)
  }

  func testMediaEntityPersistentIDConvertsSignedBitPattern() throws {
    XCTAssertEqual(mediaEntityPersistentID(fromRawValue: Int64(-1)), UInt64.max)
    XCTAssertEqual(mediaEntityPersistentID(fromRawValue: Int64(42)), 42)
    XCTAssertEqual(mediaEntityPersistentID(fromRawValue: UInt64.max), UInt64.max)
    XCTAssertNil(mediaEntityPersistentID(fromRawValue: "not an id"))
  }

  func testBuildSongsCollectionTreeNestsCollectionsUnderKnownParents() throws {
    let collections = [
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

    let tree = buildSongsCollectionTree(from: collections)

    XCTAssertEqual(tree.map(\.collection.name), ["Folder A", "Playlist B"])
    XCTAssertTrue(tree[0].isFolder)
    XCTAssertEqual(tree[0].children?.map(\.collection.name), ["Playlist A"])
    XCTAssertNil(tree[1].children)
  }

  func testBuildSongsCollectionTreeKeepsCollectionsWithCyclicParentsVisible() throws {
    let collections = [
      SongsCollection(
        name: "Folder A",
        id: "folder-a",
        type: .playlist,
        items: nil,
        parentID: "folder-b",
        isFolder: true
      ),
      SongsCollection(
        name: "Folder B",
        id: "folder-b",
        type: .playlist,
        items: nil,
        parentID: "folder-a",
        isFolder: true
      ),
    ]

    let tree = buildSongsCollectionTree(from: collections)

    XCTAssertEqual(tree.map(\.collection.name), ["Folder A"])
    XCTAssertEqual(tree.first?.children?.map(\.collection.name), ["Folder B"])
  }

  func testFolderTreeNodeBuildsSongsListFromDescendantPlaylistsWithoutSearchCriteria()
    throws
  {
    let collections = [
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
        items: nil,
        parentID: "folder-a"
      ),
    ]

    let folderNode = try XCTUnwrap(buildSongsCollectionTree(from: collections).first)
    let songsList = folderNode.songsList()

    XCTAssertEqual(folderNode.playableCollections.map(\.name), ["Playlist A", "Playlist B"])
    XCTAssertEqual(songsList.title, "Folder A")
    XCTAssertTrue(songsList.searchCriteria.isEmpty)
  }

  func testBuildSongsCollectionTreePromotesCollectionsWithMissingParents() throws {
    let collections = [
      SongsCollection(
        name: "Orphan Playlist",
        id: "orphan",
        type: .playlist,
        items: nil,
        parentID: "missing-folder"
      )
    ]

    let tree = buildSongsCollectionTree(from: collections)

    XCTAssertEqual(tree.map(\.collection.name), ["Orphan Playlist"])
    XCTAssertNil(tree.first?.children)
  }
}
