//
//  ContentView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    private enum Tab {
        case Library, NowPlaying
    }

    @State private var selectedTab: Tab = .Library
    @State private var isSettingsPresented = false
    @AppStorage(TrackPreviewMode.storageKey) private var trackPreviewModeRawValue =
        TrackPreviewMode.defaultMode.rawValue

    @StateObject private var viewModel: ContentViewModel
    @StateObject private var trackPreviewController: TrackPreviewController

    @MainActor
    init(
        viewModel: ContentViewModel? = nil,
        trackPreviewController: TrackPreviewController? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel ?? ContentViewModel())
        _trackPreviewController = StateObject(
            wrappedValue: trackPreviewController ?? TrackPreviewController()
        )
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationView {
                    List {
                        Section {
                            ForEach(CollectionTypes.allCases, id: \.self) { type in
                                NavigationLink {
                                    SongsCollectionsListView(
                                        type: type,
                                        title: type.rawValue,
                                        viewModel: viewModel.songsCollectionsListViewModel(
                                            for: type)
                                    )
                                } label: {
                                    Label(type.rawValue, systemImage: type.systemImageName)
                                }
                            }
                        }

                        Section("I'm Feeling Lucky") {
                            NavigationLink {
                                QueriedSongsListViewContainer(
                                    title: "Quick Dig",
                                    songs: viewModel.quickDigSongs,
                                    predicates: viewModel.quickDigPredicates
                                )
                            } label: {
                                Label("Quick Dig", systemImage: "square.2.layers.3d")
                            }
                        }
                    }.navigationTitle("Library")
                        .navigationBarTitleDisplayMode(.inline)
                        .listStyle(.insetGrouped)
                        .navigationViewStyle(StackNavigationViewStyle())
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    isSettingsPresented = true
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                                .accessibilityLabel("Settings")
                            }
                        }
                }.tabItem {
                    Image(systemName: "books.vertical")
                        .environment(
                            \.symbolVariants, selectedTab == .Library ? .fill : .none)
                    Text("Library")
                }
                .tag(Tab.Library)
                .task {
                    await viewModel.handleNowPlayingItemDidChange()
                }

                NavigationView {
                    NowPlayingViewContainer()
                        .navigationBarTitleDisplayMode(.inline)
                        .listStyle(.insetGrouped)
                }.tabItem {
                    Image(systemName: "play")
                        .environment(
                            \.symbolVariants, selectedTab == .NowPlaying ? .fill : .none)
                    Text("Now Playing")
                }.tag(Tab.NowPlaying)
            }
            ToastView()
        }
        .environmentObject(trackPreviewController)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
        .onAppear {
            viewModel.onAppear()
            syncTrackPreviewMode()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task { await viewModel.handleScenePhaseChange(newPhase) }
        }
        .onChange(of: trackPreviewModeRawValue) { _, _ in
            syncTrackPreviewMode()
        }
    }

    private func syncTrackPreviewMode() {
        trackPreviewController.mode =
            TrackPreviewMode(rawValue: trackPreviewModeRawValue) ?? .defaultMode
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TrackPreviewMode.storageKey) private var trackPreviewModeRawValue =
        TrackPreviewMode.defaultMode.rawValue

    var body: some View {
        NavigationView {
            Form {
                Section("Track Preview") {
                    Picker("Playback", selection: selectedMode) {
                        ForEach(TrackPreviewMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Text(selectedMode.wrappedValue.description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var selectedMode: Binding<TrackPreviewMode> {
        Binding {
            TrackPreviewMode(rawValue: trackPreviewModeRawValue) ?? .defaultMode
        } set: { mode in
            trackPreviewModeRawValue = mode.rawValue
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: ContentViewModel(
                playbackNotificationManager: PreviewPlaybackNotificationManager(),
                quickDigLoader: PreviewQuickDigLoader(),
                songsCollectionsLoader: ContentPreviewSongsCollectionsLoader()
            )
        )
    }
}

private struct PreviewPlaybackNotificationManager: PlaybackNotificationManaging {
    func beginGeneratingPlaybackNotifications() {}
    func endGeneratingPlaybackNotifications() {}
}

private struct PreviewQuickDigLoader: QuickDigLoading {
    func loadQuickDig() async -> QuickDigData? {
        QuickDigData(
            songs: [],
            predicates: [
                MyMPMediaPropertyPredicate(
                    value: "House", forProperty: MPMediaItemPropertyGenre),
                MyMPMediaPropertyPredicate(
                    value: "Mika River", forProperty: MPMediaItemPropertyArtist),
            ]
        )
    }
}

private struct ContentPreviewSongsCollectionsLoader: SongsCollectionsLoading {
    func loadCollections(of type: CollectionTypes) async -> [SongsCollection] {
        switch type {
        case .playlist:
            return [
                SongsCollection(
                    name: "DJ Sets", id: "folder-dj-sets", type: .playlist, items: nil,
                    isFolder: true),
                SongsCollection(
                    name: "Warm Up", id: "playlist-warm-up", type: .playlist, items: [],
                    parentID: "folder-dj-sets"),
                SongsCollection(
                    name: "Peak Time", id: "playlist-peak-time", type: .playlist, items: [],
                    parentID: "folder-dj-sets"),
                SongsCollection(
                    name: "Recently Added", id: "playlist-recent", type: .playlist, items: []),
            ]
        case .album:
            return [
                SongsCollection(
                    name: "City Lights After Midnight", id: "album-city-lights", type: .album,
                    items: []),
                SongsCollection(
                    name: "Small Room", id: "album-small-room", type: .album, items: []),
            ]
        case .artist:
            return [
                SongsCollection(name: "Mika River", id: "artist-mika", type: .artist, items: []),
                SongsCollection(name: "Duskline", id: "artist-duskline", type: .artist, items: []),
            ]
        case .genre:
            return [
                SongsCollection(name: "House", id: "genre-house", type: .genre, items: []),
                SongsCollection(name: "Garage", id: "genre-garage", type: .genre, items: []),
            ]
        case .userGrouping:
            return [
                SongsCollection(
                    name: "Night Drive", id: "grouping-night-drive", type: .userGrouping,
                    items: []),
                SongsCollection(
                    name: "Morning", id: "grouping-morning", type: .userGrouping, items: []),
            ]
        }
    }
}
