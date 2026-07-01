import MediaPlayer
import XCTest

@testable import onraku

final class SongMetaSearchLinkTests: XCTestCase {

  func testGoogleSearchURLBuildsSearchURLWithEncodedQuery() throws {
    XCTAssertEqual(
      GoogleSearch.url(for: "Mika River feat. Duskline")?.absoluteString,
      "https://www.google.com/search?q=Mika%20River%20feat.%20Duskline"
    )
  }

  func testGoogleSearchURLRequiresNonBlankQuery() throws {
    XCTAssertNil(GoogleSearch.url(for: nil))
    XCTAssertNil(GoogleSearch.url(for: " \n\t "))
  }

  func testSpotifySearchURLBuildsSearchURLWithEncodedQuery() throws {
    XCTAssertEqual(
      SpotifySearch.url(for: "Mika River feat. Duskline")?.absoluteString,
      "https://open.spotify.com/search/Mika%20River%20feat.%20Duskline"
    )
  }

  func testSpotifySearchURLEncodesPathSeparators() throws {
    XCTAssertEqual(
      SpotifySearch.url(for: "A/B? C")?.absoluteString,
      "https://open.spotify.com/search/A%2FB%3F%20C"
    )
  }

  func testSpotifySearchURLRequiresNonBlankQuery() throws {
    XCTAssertNil(SpotifySearch.url(for: nil))
    XCTAssertNil(SpotifySearch.url(for: " \n\t "))
  }

  func testCommentLinkifierDetectsURLs() throws {
    let links = MultiLineTextLinkifier.detectLinks(
      in: "source https://example.com/path?q=1 end")

    XCTAssertEqual(links.map(\.url.absoluteString), ["https://example.com/path?q=1"])
  }

  func testCommentLinkifierNavigatesBracketedTokensToCommentSearches() throws {
    let links = MultiLineTextLinkifier.detectLinks(
      in: "memo [anime:foobar] and [ artist name ]")

    XCTAssertEqual(
      links.map(\.url.absoluteString),
      [
        "onraku-comment-search://search?query=anime:foobar",
        "onraku-comment-search://search?query=artist%20name",
      ])
  }

  func testCommentSearchLinkBuildsCommentsPredicate() throws {
    let link = try XCTUnwrap(CommentSearchLink(query: " anime:foobar "))

    XCTAssertEqual(link.query, "anime:foobar")
    XCTAssertEqual(link.title, "Comments: anime:foobar")
    XCTAssertEqual(link.predicate.value as? String, "anime:foobar")
    XCTAssertEqual(link.predicate.forProperty, MPMediaItemPropertyComments)
    XCTAssertEqual(link.predicate.comparisonType, .contains)
    XCTAssertEqual(link.songsList.title, "Comments: anime:foobar")
    XCTAssertEqual(link.songsList.searchCriteria, [link.predicate])
  }

  func testCommentLinkifierDoesNotSearchBracketsInsideURLs() throws {
    let links = MultiLineTextLinkifier.detectLinks(
      in: "source https://example.com/[anime:foobar] end")

    XCTAssertEqual(links.map(\.url.host), ["example.com"])
  }

  func testSongMetaSearchLinksBuildExpectedPredicates() throws {
    let song = DummySongDetail(
      albumArtist: "Album Artist A",
      albumTitle: "Album A",
      albumTrackCount: 0,
      albumTrackNumber: 0,
      artist: "Artist A",
      artwork: nil,
      beatsPerMinute: 0,
      comments: nil,
      isCompilation: false,
      composer: "Composer A",
      dateAdded: .now,
      discCount: 0,
      discNumber: 0,
      genre: "Genre A",
      lastPlayedDate: nil,
      lyrics: nil,
      playCount: 0,
      rating: 0,
      releaseDate: nil,
      releaseYear: nil,
      skipCount: 0,
      title: "Song A",
      userGrouping: "Grouping A",
      playbackDuration: 0,
      refreshingIdentifier: "song-1"
    )

    let links = SongMetaSearchLink.links(for: song)

    XCTAssertEqual(
      links.map(\.kind),
      [
        .artist, .album, .albumArtist, .composer, .userGrouping, .genre,
      ])
    XCTAssertEqual(
      SongMetaSearchLink.link(for: .artist, song: song).predicate.forProperty,
      MPMediaItemPropertyArtist
    )
    XCTAssertEqual(
      SongMetaSearchLink.link(for: .album, song: song).predicate.forProperty,
      MPMediaItemPropertyAlbumTitle
    )
    XCTAssertEqual(
      SongMetaSearchLink.link(for: .albumArtist, song: song).predicate.forProperty,
      MPMediaItemPropertyAlbumArtist
    )
    XCTAssertEqual(
      SongMetaSearchLink.link(for: .composer, song: song).predicate.value as? String,
      "Composer A"
    )
    XCTAssertTrue(links.allSatisfy(\.isEnabled))
  }

  func testSongMetaSearchLinkDisablesEmptyValues() throws {
    let song = makeDummySong(refreshingIdentifier: "song-1")

    XCTAssertFalse(SongMetaSearchLink.artist(for: song).isEnabled)
    XCTAssertFalse(SongMetaSearchLink.album(for: song).isEnabled)
  }

  func testSongMetaSearchLinkDisablesWhitespaceOnlyValues() throws {
    let song = DummySongDetail(
      albumArtist: nil,
      albumTitle: " \n\t ",
      albumTrackCount: 0,
      albumTrackNumber: 0,
      artist: "   ",
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
      title: "Song A",
      userGrouping: nil,
      playbackDuration: 0,
      refreshingIdentifier: "song-1"
    )

    XCTAssertFalse(SongMetaSearchLink.artist(for: song).isEnabled)
    XCTAssertFalse(SongMetaSearchLink.album(for: song).isEnabled)
  }
}
