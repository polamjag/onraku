import MediaPlayer
import XCTest

@testable import onraku

final class SongsListTests: XCTestCase {

  @MainActor
  func testSongsListFixedExposesStaticContract() async throws {
    let sut = SongsListFixed(fixedSongs: [], title: "Fixed")

    XCTAssertEqual(sut.title, "Fixed")
    XCTAssertEqual(sut.searchCriteria, [])
    XCTAssertFalse(sut.shouldShowSearchCriteria)
    let loadedSongs = await sut.loadSongs()
    XCTAssertEqual(loadedSongs.count, 0)
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
    let loadedSongs = await sut.loadSongs()
    XCTAssertEqual(loadedSongs.count, 0)
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
  func testQueriedSongsListViewModelStoresSortOrder() async throws {
    let sut = QueriedSongsListViewModel(title: "Search Result") {
      []
    }

    await sut.loadIfNeeded()
    sut.setSortOrder(.album)

    XCTAssertEqual(sut.sortOrder, .album)
    XCTAssertTrue(sut.displayedSongs.isEmpty)
  }
}
