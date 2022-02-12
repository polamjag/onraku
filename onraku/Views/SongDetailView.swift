//
//  SongDetailView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

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
    var lyrics: String? { get }
    var playCount: Int { get }
    var rating: Int { get }
    var releaseDate: Date? { get }
    var skipCount: Int { get }
    var title: String? { get }
    var userGrouping: String? { get }
    var playbackDuration: TimeInterval { get }
}

private struct DummySongDetail: SongDetailLike {
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
    var lyrics: String?
    var playCount: Int
    var rating: Int
    var releaseDate: Date?
    var skipCount: Int
    var title: String?
    var userGrouping: String?
    var playbackDuration: TimeInterval
}

extension MPMediaItem: SongDetailLike {}

func getYear(item: MPMediaItem) -> Int? {
    // https://stackoverflow.com/questions/45254471/release-date-of-mpmediaitem-returning-nil-swift-4
    let yearNumber: NSNumber = item.value(forProperty: "year") as! NSNumber
    if yearNumber.isKind(of: NSNumber.self) {
        let year = yearNumber.intValue
        if year != 0 {
            return year
        }
    }
    return nil
}

private let artworkSize: CGFloat = 128
private let formatter = DateComponentsFormatter()

struct SongDetailView: View {
    var song: SongDetailLike

    var body: some View {
        List {
            KeyValueView(key: "title", value: song.title)

            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: song.artist, forProperty: MPMediaItemPropertyArtist))
            } label: {
                KeyValueView(key: "artist", value: song.artist)
            }.disabled(song.artist?.isEmpty ?? true)

            NavigationLink {
                if let song = song as? MPMediaItem {
                    QueriedSongsListViewContainer(
                        filterPredicate: MyMPMediaPropertyPredicate(
                            value: song.albumPersistentID,
                            forProperty: MPMediaItemPropertyAlbumPersistentID),
                        title: song.albumTitle)
                } else {
                    QueriedSongsListViewContainer(
                        filterPredicate: MyMPMediaPropertyPredicate(
                            value: song.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle),
                        title: song.albumTitle)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        KeyValueView(key: "album", value: song.albumTitle)

                        Spacer()

                        Divider()

                        VStack(alignment: .leading) {
                            Text("Track \(song.albumTrackNumber) of \(song.albumTrackCount)").font(
                                .footnote)
                            if song.discCount > 1 || song.discNumber > 1 {
                                Text("Disc \(song.discNumber) of \(song.discCount)").font(.footnote)
                            }
                        }

                        Spacer()

                        if let releaseDate = song.releaseDate {
                            KeyValueView(
                                key: "released at",
                                value: releaseDate.formatted(date: .abbreviated, time: .omitted))
                        } else if let mpitem = song as? MPMediaItem,
                            let year = getYear(item: mpitem)
                        {
                            KeyValueView(key: "released at", value: String(year))
                        }
                    }
                    Spacer()

                    if let image = song.artwork?.image(
                        at: CGSize(width: artworkSize, height: artworkSize))
                    {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: artworkSize, height: artworkSize)
                            .cornerRadius(4)
                    }
                }
            }.disabled(song.albumTitle?.isEmpty ?? true)

            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: song.albumArtist, forProperty: MPMediaItemPropertyArtist))
            } label: {
                KeyValueView(key: "album artist", value: song.albumArtist)
            }.disabled(song.albumArtist?.isEmpty ?? true)

            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: song.composer, forProperty: MPMediaItemPropertyComposer))
            } label: {
                KeyValueView(key: "composer", value: song.composer)
            }.disabled(song.composer?.isEmpty ?? true)

            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: song.userGrouping, forProperty: MPMediaItemPropertyUserGrouping))
            } label: {
                HorizontalKeyValueView(key: "user grouping", value: song.userGrouping)
            }.disabled(song.userGrouping?.isEmpty ?? true)

            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: song.genre, forProperty: MPMediaItemPropertyGenre))
            } label: {
                HorizontalKeyValueView(key: "genre", value: song.genre)
            }.disabled(song.genre?.isEmpty ?? true)

            Group {
                HorizontalKeyValueView(key: "bpm", value: String(song.beatsPerMinute))
                HorizontalKeyValueView(
                    key: "playback time", value: formatter.string(from: song.playbackDuration))

                HStack {
                    Text("rating").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    if 0 < song.rating && song.rating <= 5 {
                        FiveStarsImageView(rating: song.rating)
                    } else {
                        Text("-").foregroundColor(.secondary)
                    }
                }.lineLimit(1)

                HorizontalKeyValueView(key: "skip count", value: String(song.skipCount))
                HorizontalKeyValueView(key: "play count", value: String(song.playCount))
                HorizontalKeyValueView(
                    key: "total playback time",
                    value: formatter.string(from: song.playbackDuration * Double(song.playCount)))
            }

            Group {
                HorizontalKeyValueView(key: "added at", value: song.dateAdded.formatted())

                NavigationLink {
                    MultiLineTextView(text: song.comments ?? "")
                } label: {
                    HorizontalKeyValueView(key: "comments", value: song.comments)
                }.disabled(song.comments?.isEmpty ?? true)

                NavigationLink {
                    MultiLineTextView(text: song.lyrics ?? "")
                } label: {
                    HorizontalKeyValueView(key: "lyrics", value: song.lyrics)
                }.disabled(song.lyrics?.isEmpty ?? true)
            }
        }.navigationTitle(song.title ?? "Song Detail").toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    PlayableContentMenuView(target: [song as! MPMediaItem])
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct FiveStarsImageView: View {
    var rating: Int
    var body: some View {
        HStack {
            if 0 < rating && rating <= 5 {
                Group {
                    ForEach(1...rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                    }
                    if rating < 5 {
                        ForEach(1...(5 - rating), id: \.self) { _ in
                            Image(systemName: "star")
                        }
                    }
                }
            }
        }.accessibilityLabel("\(rating) stars")
    }
}

private struct KeyValueView: View {
    var key: String
    var value: String?
    var fallbackValue: String = "-"

    var body: some View {
        VStack(alignment: .leading) {
            Text(key).font(.footnote).foregroundColor(.secondary)
            if let str = value, !str.isEmpty {
                Text(str)
            } else {
                Text(fallbackValue).foregroundColor(.secondary)
            }
        }
    }
}

private struct HorizontalKeyValueView: View {
    var key: String
    var value: String?
    var fallbackValue: String = "-"

    var body: some View {
        HStack {
            Text(key).font(.footnote).foregroundColor(.secondary)
            Spacer()
            if let str = value, !str.isEmpty {
                Text(str)
            } else {
                Text(fallbackValue).foregroundColor(.secondary)
            }
        }.lineLimit(1)
    }
}

struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SongDetailView(
            song: DummySongDetail(
                albumArtist: "some album artist",
                albumTitle: "ultra album",
                albumTrackCount: 12,
                albumTrackNumber: 3,
                artist: "super artist",
                artwork: MPMediaItemArtwork.init(
                    boundsSize: CGSize(width: 48, height: 48),
                    requestHandler: { _ in UIImage.checkmark }),
                beatsPerMinute: 124,
                comments: "hello this is comments",
                isCompilation: false,
                composer: "old composer",
                dateAdded: Date(timeIntervalSince1970: 1_644_649_595),
                discCount: 5,
                discNumber: 3,
                genre: "Super Dance Music",
                lyrics: "Lorem ipsum",
                playCount: 123,
                rating: 4,
                releaseDate: Date(timeIntervalSince1970: 1_644_649_595),
                skipCount: 12,
                title: "Super Song",
                userGrouping: "Ultra Grouping",
                playbackDuration: TimeInterval(120)
            ))
    }
}
