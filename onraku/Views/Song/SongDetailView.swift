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
            HStack {
                Label(aiCreditAnalysisButtonTitle, systemImage: aiCreditAnalysisButtonSystemImage)
                if isAnalyzingCredits {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isAnalyzingCredits)
        }
        .buttonStyle(.borderless)
        .disabled(isAnalyzingCredits)

        switch titleCredits.state {
        case .idle:
            EmptyView()
        case .loading(let previousResult):
            if let previousResult {
                creditAnalysisResultView(previousResult)
            } else {
                creditAnalysisSkeletonView()
            }
        case .loaded(let result):
            creditAnalysisResultView(result)
        case .unavailable(let reason), .failed(let reason):
            Text(reason).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func creditAnalysisResultView(_ result: TitleCreditExtractionResult) -> some View {
        if result.isEmpty {
            Text("No explicit credits found.").foregroundStyle(.secondary)
        } else {
            creditLinks(title: "remixer", artists: result.remixers)
            creditLinks(title: "featured", artists: result.featuredArtists)
        }
    }

    private func creditAnalysisSkeletonView() -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(.secondary.opacity(0.22))
                .frame(width: 72, height: 12)
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(.secondary.opacity(0.16))
                .frame(width: 128, height: 12)
        }
        .frame(minHeight: 24)
        .redacted(reason: .placeholder)
    }

    private var isAnalyzingCredits: Bool {
        if case .loading = titleCredits.state {
            return true
        }
        return false
    }

    private var aiCreditAnalysisButtonTitle: String {
        switch titleCredits.state {
        case .idle:
            return "Analyze Credits with AI"
        case .loading(let previousResult):
            return previousResult == nil
                ? "Analyzing Credits with AI"
                : "Retaking Credits with AI"
        case .loaded:
            return "Retake Credits with AI"
        case .unavailable, .failed:
            return "Retry Credits with AI"
        }
    }

    private var aiCreditAnalysisButtonSystemImage: String {
        switch titleCredits.state {
        case .idle:
            return "sparkles"
        case .loading(let previousResult):
            return previousResult == nil
                ? "sparkles"
                : "arrow.triangle.2.circlepath"
        case .loaded:
            return "arrow.triangle.2.circlepath"
        case .unavailable, .failed:
            return "arrow.clockwise"
        }
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
