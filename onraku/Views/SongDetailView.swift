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
}

extension MPMediaItem: SongDetailLike {}

private let artworkSize: CGFloat = 128
private let formatter = DateComponentsFormatter()

struct SongDetailView: View {
  var song: SongDetailLike
  var title: String?

  @StateObject private var digDeeperItems = DiggingViewModel()
  @StateObject private var digDeepestItems = DiggingViewModel()

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
              value: song.albumTitle, forProperty: MPMediaItemPropertyAlbumTitle
            ),
            title: song.albumTitle)
        }
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
            value: song.userGrouping,
            forProperty: MPMediaItemPropertyUserGrouping))
      } label: {
        KeyValueView(key: "user grouping", value: song.userGrouping)
      }.disabled(song.userGrouping?.isEmpty ?? true)

      NavigationLink {
        QueriedSongsListViewContainer(
          filterPredicate: MyMPMediaPropertyPredicate(
            value: song.genre, forProperty: MPMediaItemPropertyGenre))
      } label: {
        KeyValueView(key: "genre", value: song.genre)
      }.disabled(song.genre?.isEmpty ?? true)

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
          key: "total playback time",
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

      Section {
        NavigationLink {
          QueriedSongsListViewContainer(
            title: "Dig Deeper",
            songs: digDeeperItems.songs,
            predicates: digDeeperItems.predicates
          )
        } label: {
          SongsCollectionItemView(
            title: "Dig Deeper", systemImage: "square.2.layers.3d",
            itemsCount: digDeeperItems.songs.count,
            showLoading: digDeeperItems.loadingState == .loading)
        }

        NavigationLink {
          QueriedSongsListViewContainer(
            title: "Dig Deepest", songs: digDeepestItems.songs,
            predicates: digDeepestItems.predicates)
        } label: {
          SongsCollectionItemView(
            title: "Dig Deepest", systemImage: "square.3.layers.3d",
            itemsCount: digDeepestItems.songs.count,
            showLoading: digDeepestItems.loadingState == .loading)
        }
      }.task {
        Task {
          await digDeeperItems.load(for: song as! MPMediaItem, withDepth: 1)
        }
        Task {
          await digDeepestItems.load(for: song as! MPMediaItem, withDepth: 2)
        }
      }
    }.navigationTitle(title ?? song.title ?? "Song Detail").toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Menu {
          PlayableItemsMenuView(target: .array([song as! MPMediaItem]))
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
  }
}

class DiggingViewModel: ObservableObject {
  @MainActor @Published var songs: [MPMediaItem] = []
  @MainActor @Published var predicates: [MyMPMediaPropertyPredicate] = []
  @MainActor @Published var loadingState: LoadingState = .initial

  @MainActor func load(for song: MPMediaItem, withDepth linkDepth: Int) async {
    self.loadingState = .loading

    let items = Task.detached {
      () -> (
        items: [MPMediaItem],
        predicates: [MyMPMediaPropertyPredicate]
      ) in
      await getDiggedItems(
        of: song, includeGenre: false, withDepth: linkDepth)
    }

    let res = await items.result.get()
    self.songs = res.items
    self.predicates = res.predicates
    self.loadingState = .loaded
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

//struct SongDetailView_Previews: PreviewProvider {
//  static var previews: some View {
//    SongDetailView(
//      song: DummySongDetail(
//        albumArtist: "some album artist",
//        albumTitle: "ultra album",
//        albumTrackCount: 12,
//        albumTrackNumber: 3,
//        artist: "super artist",
//        artwork: MPMediaItemArtwork.init(
//          boundsSize: CGSize(width: 48, height: 48),
//          requestHandler: { _ in UIImage.checkmark }),
//        beatsPerMinute: 124,
//        comments: "hello this is comments",
//        isCompilation: false,
//        composer: "old composer",
//        dateAdded: Date(timeIntervalSince1970: 1_644_649_595),
//        discCount: 5,
//        discNumber: 3,
//        genre: "Super Dance Music",
//        lyrics: "Lorem ipsum",
//        playCount: 123,
//        rating: 4,
//        releaseDate: Date(timeIntervalSince1970: 1_644_649_595),
//        skipCount: 12,
//        title: "Super Song",
//        userGrouping: "Ultra Grouping",
//        playbackDuration: TimeInterval(120)
//      ))
//  }
//}
