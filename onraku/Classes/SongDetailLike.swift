//
//  SongDetailLike.swift
//  onraku
//
//  Created by Satoru Abe on 2025/05/06.
//

import MediaPlayer

protocol SongDetailLike {
    var albumArtist: String? { get }
    var albumTitle: String? { get }
    var albumTrackCount: Int { get }
    var albumTrackNumber: Int { get }
    var artist: String? { get }
    var artwork: MPMediaItemArtwork? { get }
    var beatsPerMinute: Int { get }
    var comments: String? { get }
    var isCompilation: Bool { get }
    var composer: String? { get }
    var dateAdded: Date { get }
    var discCount: Int { get }
    var discNumber: Int { get }
    var genre: String? { get }
    var lastPlayedDate: Date? { get }
    var lyrics: String? { get }
    var playCount: Int { get }
    var rating: Int { get }
    var releaseDate: Date? { get }
    var releaseYear: Int? { get }
    var skipCount: Int { get }
    var title: String? { get }
    var userGrouping: String? { get }
    var playbackDuration: TimeInterval { get }
    var refreshingIdentifier: String { get }
}

struct DummySongDetail: SongDetailLike {
    var albumArtist: String?
    var albumTitle: String?
    var albumTrackCount: Int
    var albumTrackNumber: Int
    var artist: String?
    var artwork: MPMediaItemArtwork?
    var beatsPerMinute: Int
    var comments: String?
    var isCompilation: Bool
    var composer: String?
    var dateAdded: Date
    var discCount: Int
    var discNumber: Int
    var genre: String?
    var lastPlayedDate: Date?
    var lyrics: String?
    var playCount: Int
    var rating: Int
    var releaseDate: Date?
    var releaseYear: Int?
    var skipCount: Int
    var title: String?
    var userGrouping: String?
    var playbackDuration: TimeInterval
    var refreshingIdentifier: String
}

extension DummySongDetail {
    static let preview = DummySongDetail(
        albumArtist: "Night Transit Orchestra",
        albumTitle: "City Lights After Midnight",
        albumTrackCount: 12,
        albumTrackNumber: 3,
        artist: "Mika River feat. Duskline",
        artwork: nil,
        beatsPerMinute: 124,
        comments: "Preview comments for checking the metadata sheet layout.",
        isCompilation: false,
        composer: "Satoru Keys",
        dateAdded: Date(timeIntervalSince1970: 1_644_649_595),
        discCount: 2,
        discNumber: 1,
        genre: "House / Garage",
        lastPlayedDate: Date(timeIntervalSince1970: 1_708_214_400),
        lyrics: "First line\nSecond line\nThird line",
        playCount: 123,
        rating: 4,
        releaseDate: Date(timeIntervalSince1970: 1_609_459_200),
        releaseYear: nil,
        skipCount: 12,
        title: "Supernova Drive (Kohei Remix)",
        userGrouping: "Night Drive",
        playbackDuration: 224,
        refreshingIdentifier: "preview-song"
    )

    static let minimalPreview = DummySongDetail(
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
        dateAdded: Date(timeIntervalSince1970: 1_644_649_595),
        discCount: 0,
        discNumber: 0,
        genre: nil,
        lastPlayedDate: nil,
        lyrics: nil,
        playCount: 0,
        rating: 0,
        releaseDate: nil,
        releaseYear: 2024,
        skipCount: 0,
        title: nil,
        userGrouping: nil,
        playbackDuration: 0,
        refreshingIdentifier: "preview-minimal-song"
    )
}

extension MPMediaItem: SongDetailLike {}
