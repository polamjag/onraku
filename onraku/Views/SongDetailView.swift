//
//  SongDetailView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/12.
//

import MediaPlayer
import SwiftUI

struct SongDetailView: View {
  var song: SongDetailLike
  var title: String?

  @StateObject private var digDeeperItems = DiggingViewModel()
  @StateObject private var digDeepestItems = DiggingViewModel()

  @StateObject private var playlistsOfSong = PlaylistsBySongViewModel()

  var body: some View {
    List {
      SongMetaView(song: song)

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
            showLoading: digDeeperItems.loadingState.isLoading)
        }

        NavigationLink {
          QueriedSongsListViewContainer(
            title: "Dig Deepest",
            songs: digDeepestItems.songs,
            predicates: digDeepestItems.predicates
          )
        } label: {
          SongsCollectionItemView(
            title: "Dig Deepest", systemImage: "square.3.layers.3d",
            itemsCount: digDeepestItems.songs.count,
            showLoading: digDeepestItems.loadingState.isLoading)
        }
      }

      Section("Show in Playlist") {
        playlistsView()
      }
    }.navigationTitle(title ?? song.title ?? "Song Detail").toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Menu {
          PlayableItemsMenuView(target: .array([song as! MPMediaItem]))
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }.task {
      _ = await [
        digDeeperItems.load(for: song as! MPMediaItem, withDepth: 1),
        digDeepestItems.load(for: song as! MPMediaItem, withDepth: 2),
        playlistsOfSong.load(for: song as! MPMediaItem),
      ]
    }
  }

  private func playlistsView() -> some View {
    Group {
      if playlistsOfSong.loadingState.isLoading {
        HStack(alignment: .center) {
          ProgressView()
        }
      } else {
        if playlistsOfSong.playlists.isEmpty {
          Text("no playlists").foregroundStyle(.secondary)
        } else {
          ForEach(playlistsOfSong.playlists) { playlist in
            NavigationLink {
              QueriedSongsListViewContainer(
                title: playlist.name, songs: playlist.items ?? []
              )
            } label: {
              SongsCollectionItemView(
                title: playlist.name
              )
            }
          }
        }
      }
    }
  }
}

class PlaylistsBySongViewModel: ObservableObject {
  @MainActor @Published var playlists: [SongsCollection] = []
  @MainActor @Published var loadingState: LoadingState = .initial

  @MainActor func load(for song: MPMediaItem) async {
    self.loadingState = .loading

    let items = Task.detached {
      () -> [SongsCollection] in await getPlaylistsBySong(song)
    }

    let res = await items.result.get()
    self.playlists = res
    self.loadingState = .loaded
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
