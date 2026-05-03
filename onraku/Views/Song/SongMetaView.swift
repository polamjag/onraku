//
//  SongMetaView.swift
//  onraku
//
//  Created by Satoru Abe on 2025/05/06.
//

import MediaPlayer
import SwiftUI

private let artworkSize: CGFloat = 128
private let formatter = DateComponentsFormatter()

struct SongMetaView: View {
    var song: SongDetailLike

    var body: some View {
        KeyValueView(key: "title", value: song.title)

        NavigationLink {
            searchDestination(for: .artist)
        } label: {
            KeyValueView(key: "artist", value: song.artist)
        }.disabled(!searchLink(for: .artist).isEnabled)

        NavigationLink {
            searchDestination(for: .album)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    KeyValueView(key: "album", value: song.albumTitle)

                    Spacer()

                    Divider()

                    VStack(alignment: .leading) {
                        Text("Track \(song.albumTrackNumber) of \(song.albumTrackCount)")
                            .font(
                                .footnote)
                        if song.discCount > 1 || song.discNumber > 1 {
                            Text("Disc \(song.discNumber) of \(song.discCount)").font(
                                .footnote)
                        }
                    }

                    Spacer()

                    if let releaseDate = song.releaseDate {
                        KeyValueView(
                            key: "released at",
                            value: releaseDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    } else if let year = song.releaseYear {
                        KeyValueView(key: "released at", value: String(year))
                    }
                }
                Spacer()

                if let image = song.artwork?.image(
                    at: CGSize(width: artworkSize, height: artworkSize))
                {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: artworkSize, height: artworkSize)
                        .cornerRadius(4)
                }
            }
        }.disabled(!searchLink(for: .album).isEnabled)

        NavigationLink {
            searchDestination(for: .albumArtist)
        } label: {
            KeyValueView(key: "album artist", value: song.albumArtist)
        }.disabled(!searchLink(for: .albumArtist).isEnabled)

        NavigationLink {
            searchDestination(for: .composer)
        } label: {
            KeyValueView(key: "composer", value: song.composer)
        }.disabled(!searchLink(for: .composer).isEnabled)

        NavigationLink {
            searchDestination(for: .userGrouping)
        } label: {
            KeyValueView(key: "user grouping", value: song.userGrouping)
        }.disabled(!searchLink(for: .userGrouping).isEnabled)

        NavigationLink {
            searchDestination(for: .genre)
        } label: {
            KeyValueView(key: "genre", value: song.genre)
        }.disabled(!searchLink(for: .genre).isEnabled)

        Group {
            HorizontalKeyValueView(key: "bpm", value: String(song.beatsPerMinute))
            HorizontalKeyValueView(
                key: "playback time",
                value: formatter.string(from: song.playbackDuration))

            HStack {
                Text("rating").font(.footnote).foregroundColor(.secondary)
                Spacer()
                if 0 < song.rating && song.rating <= 5 {
                    FiveStarsImageView(rating: song.rating)
                } else {
                    Text("-").foregroundColor(.secondary)
                }
            }.lineLimit(1)

            //                HorizontalKeyValueView(key: "skip count", value: String(song.skipCount))
            HorizontalKeyValueView(key: "play count", value: String(song.playCount))
            HorizontalKeyValueView(
                key: "played this song for",
                value: formatter.string(
                    from: song.playbackDuration * Double(song.playCount)))
        }

        Group {
            HorizontalKeyValueView(
                key: "last played at", value: song.lastPlayedDate?.formatted())

            HorizontalKeyValueView(
                key: "added at", value: song.dateAdded.formatted())

            HorizontalKeyValueToSheetView(key: "comments", value: song.comments)
            HorizontalKeyValueToSheetView(key: "lyrics", value: song.lyrics)
        }
    }

    private func searchLink(for kind: SongMetaSearchLink.Kind) -> SongMetaSearchLink {
        SongMetaSearchLink.link(for: kind, song: song)
    }

    private func searchDestination(for kind: SongMetaSearchLink.Kind)
        -> QueriedSongsListViewContainer
    {
        let link = searchLink(for: kind)
        return QueriedSongsListViewContainer(
            filterPredicate: link.predicate,
            title: link.title
        )
    }
}

private struct KeyValueView: View {
    var key: String
    var value: String?
    var fallbackValue: String = "-"

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
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

private struct HorizontalKeyValueToSheetView: View {
    var key: String
    var value: String?
    @State private var isSheetShowing: Bool = false

    var isSheetAvailable: Bool {
        ((value?.isEmpty) == false)
    }

    var body: some View {
        HorizontalKeyValueView(key: key, value: value)
            .onTapGesture {
                if isSheetAvailable {
                    isSheetShowing = true
                }
            }
            .sheet(
                isPresented: $isSheetShowing, onDismiss: { isSheetShowing = false },
                content: {
                    MultiLineTextView(text: value ?? "")
                }
            ).disabled(!isSheetAvailable)
    }
}

struct SongMetaView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                SongMetaView(song: DummySongDetail.preview)
            }
            .navigationTitle("Song Meta")
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Complete")

        NavigationView {
            List {
                SongMetaView(song: DummySongDetail.minimalPreview)
            }
            .navigationTitle("Song Meta")
            .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("Missing Values")
    }
}
