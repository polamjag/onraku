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

    @StateObject private var digDeeperItems: DiggingViewModel
    @StateObject private var digDeepestItems: DiggingViewModel

    @StateObject private var playlistsOfSong: PlaylistsBySongViewModel
    @StateObject private var titleCredits: TitleCreditExtractionViewModel

    @MainActor
    init(
        song: SongDetailLike,
        title: String? = nil,
        digDeeperItems: DiggingViewModel? = nil,
        digDeepestItems: DiggingViewModel? = nil,
        playlistsOfSong: PlaylistsBySongViewModel? = nil,
        titleCredits: TitleCreditExtractionViewModel? = nil
    ) {
        self.song = song
        self.title = title
        _digDeeperItems = StateObject(
            wrappedValue: digDeeperItems ?? DiggingViewModel()
        )
        _digDeepestItems = StateObject(
            wrappedValue: digDeepestItems ?? DiggingViewModel()
        )
        _playlistsOfSong = StateObject(
            wrappedValue: playlistsOfSong ?? PlaylistsBySongViewModel()
        )
        _titleCredits = StateObject(
            wrappedValue: titleCredits ?? TitleCreditExtractionViewModel()
        )
    }

    private var mediaItem: MPMediaItem? {
        song as? MPMediaItem
    }

    var body: some View {
        List {
            SongMetaView(song: song)

            if mediaItem != nil {
                Section("AI Credit Analysis") {
                    aiCreditAnalysisView()
                }

                Section {
                    NavigationLink {
                        QueriedSongsListViewContainer(
                            songsList: digDeeperItems.songsList(title: "Dig Deeper"),
                        )
                    } label: {
                        SongsCollectionItemView(
                            title: "Dig Deeper", systemImage: "square.2.layers.3d",
                            itemsCount: digDeeperItems.songs.count,
                            showLoading: digDeeperItems.loadingState.isLoading)
                    }.disabled(
                        digDeeperItems.loadingState.isLoading || digDeeperItems.songs.isEmpty)

                    NavigationLink {
                        QueriedSongsListViewContainer(
                            songsList: digDeepestItems.songsList(title: "Dig Deepest"),
                        )
                    } label: {
                        SongsCollectionItemView(
                            title: "Dig Deepest", systemImage: "square.3.layers.3d",
                            itemsCount: digDeepestItems.songs.count,
                            showLoading: digDeepestItems.loadingState.isLoading)
                    }.disabled(
                        digDeepestItems.loadingState.isLoading || digDeepestItems.songs.isEmpty)
                }

                Section("Show in Playlist") {
                    playlistsView()
                }
            }
        }.navigationTitle(title ?? song.title ?? "Song Detail").toolbar {
            if let mediaItem {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        PlayableItemsMenuView(item: mediaItem)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }.task(id: mediaItem?.refreshingIdentifier ?? song.refreshingIdentifier) {
            titleCredits.reset()
            _ = await (
                digDeeperItems.load(for: song, withDepth: 1),
                digDeepestItems.load(for: song, withDepth: 2),
                playlistsOfSong.load(for: song)
            )
        }
    }

    @ViewBuilder
    private func aiCreditAnalysisView() -> some View {
        Button {
            Task {
                await titleCredits.extractCredits(for: song)
            }
        } label: {
            Label("Analyze Credits with AI", systemImage: "sparkles")
        }
        .disabled(isAnalyzingCredits)

        switch titleCredits.state {
        case .idle:
            EmptyView()
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        case .loaded(let result):
            if result.isEmpty {
                Text("No explicit credits found.").foregroundStyle(.secondary)
            } else {
                creditLinks(title: "remixer", artists: result.remixers)
                creditLinks(title: "featured", artists: result.featuredArtists)
            }
        case .unavailable(let reason), .failed(let reason):
            Text(reason).foregroundStyle(.secondary)
        }
    }

    private var isAnalyzingCredits: Bool {
        if case .loading = titleCredits.state {
            return true
        }
        return false
    }

    @ViewBuilder
    private func creditLinks(title: String, artists: [String]) -> some View {
        ForEach(artists, id: \.self) { artist in
            NavigationLink {
                QueriedSongsListViewContainer(
                    filterPredicate: MyMPMediaPropertyPredicate(
                        value: artist, forProperty: MPMediaItemPropertyArtist,
                        comparisonType: .contains),
                    title: artist)
            } label: {
                HStack {
                    Text(title).font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text(artist)
                }
            }
        }
    }

    @ViewBuilder
    private func playlistsView() -> some View {
        if playlistsOfSong.loadingState.isLoading {
            HStack(alignment: .center) {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if playlistsOfSong.playlists.isEmpty {
            Text("no playlists").foregroundStyle(.secondary)
        } else {
            ForEach(playlistsOfSong.playlists) { playlist in
                NavigationLink {
                    QueriedSongsListViewContainer(
                        songsList: SongsListLoaded(
                            loadedSongs: playlist.items ?? [],
                            title: playlist.name,
                            predicates: []
                        )
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

struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SongDetailView(song: DummySongDetail.preview)
        }
        .previewDisplayName("Song Detail")

        NavigationView {
            SongDetailView(song: DummySongDetail.minimalPreview, title: "Now Playing")
        }
        .previewDisplayName("Missing Values")
    }
}
