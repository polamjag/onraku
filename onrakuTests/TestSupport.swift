import MediaPlayer

@testable import onraku

final class FakePlaybackNotificationManager: PlaybackNotificationManaging {
  private(set) var beginCallCount = 0
  private(set) var endCallCount = 0

  func beginGeneratingPlaybackNotifications() {
    beginCallCount += 1
  }

  func endGeneratingPlaybackNotifications() {
    endCallCount += 1
  }
}

final class FakeQuickDigLoader: QuickDigLoading {
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

final class FakeNowPlayingLoader: NowPlayingLoading {
  private(set) var loadCallCount = 0
  var result: MPMediaItem?

  func loadNowPlayingSong() async -> MPMediaItem? {
    loadCallCount += 1
    return result
  }
}

final class FakeDiggingLoader: DiggingLoading {
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

final class FakeSongPlaylistLoader: SongPlaylistLoading {
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

final class FakeSongsCollectionsLoader: SongsCollectionsLoading {
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

struct FakeSongsList: SongsList {
  let title: String
  let searchCriteria: [MyMPMediaPropertyPredicate]
  let loader: () async -> [MPMediaItem]

  func loadSongs() async -> [MPMediaItem] {
    await loader()
  }
}

func makeDummySong(
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
