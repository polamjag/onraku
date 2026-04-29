import MediaPlayer
import XCTest

@testable import onraku

final class SongMetaSearchLinkTests: XCTestCase {

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
}
