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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private enum Tab {
        case library, nowPlaying
    }

    private enum SidebarDestination: Hashable {
        case collection(String)
        case quickDig
        case nowPlaying
    }

    @State private var selectedTab: Tab = .library
    @State private var selectedSidebarDestination: SidebarDestination? =
        .collection(CollectionTypes.playlist.rawValue)
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
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                compactLayout
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

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                compactLibraryList
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "books.vertical")
                    .environment(
                        \.symbolVariants, selectedTab == .library ? .fill : .none)
                Text("Library")
            }
            .tag(Tab.library)
            .task {
                await viewModel.handleNowPlayingItemDidChange()
            }

            NavigationView {
                NowPlayingViewContainer()
                    .navigationBarTitleDisplayMode(.inline)
                    .listStyle(.insetGrouped)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "play")
                    .environment(
                        \.symbolVariants, selectedTab == .nowPlaying ? .fill : .none)
                Text("Now Playing")
            }
            .tag(Tab.nowPlaying)
        }
    }

    private var compactLibraryList: some View {
        List {
            Section {
                ForEach(CollectionTypes.allCases, id: \.self) { type in
                    NavigationLink {
                        collectionList(for: type)
                    } label: {
                        Label(type.rawValue, systemImage: type.systemImageName)
                    }
                }
            }

            Section("I'm Feeling Lucky") {
                NavigationLink {
                    quickDigView
                } label: {
                    Label("Quick Dig", systemImage: "square.2.layers.3d")
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .toolbar {
            settingsToolbarItem
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarDestination) {
                Section("Library") {
                    ForEach(CollectionTypes.allCases, id: \.self) { type in
                        NavigationLink(value: SidebarDestination.collection(type.rawValue)) {
                            Label(type.rawValue, systemImage: type.systemImageName)
                        }
                    }
                }

                Section("I'm Feeling Lucky") {
                    NavigationLink(value: SidebarDestination.quickDig) {
                        Label("Quick Dig", systemImage: "square.2.layers.3d")
                    }
                }

                Section("Playback") {
                    NavigationLink(value: SidebarDestination.nowPlaying) {
                        Label("Now Playing", systemImage: "play")
                    }
                }

                Section("App") {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Settings")
                }
            }
            .listStyle(.sidebar)
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .contentMargins(.top, 8, for: .scrollContent)
            .listSectionSpacing(.compact)
            .navigationTitle("onraku")
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
        } detail: {
            NavigationStack {
                iPadDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await viewModel.handleNowPlayingItemDidChange()
        }
    }

    @ViewBuilder
    private var iPadDetail: some View {
        switch selectedSidebarDestination {
        case .collection(let rawValue):
            if let type = CollectionTypes(rawValue: rawValue) {
                collectionList(for: type)
            }
        case .quickDig:
            quickDigView
        case .nowPlaying:
            NowPlayingViewContainer()
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(.insetGrouped)
        case nil:
            ContentUnavailableView(
                "Select a Library",
                systemImage: "books.vertical",
                description: Text("Choose an item from the sidebar.")
            )
        }
    }

    private func collectionList(for type: CollectionTypes) -> some View {
        SongsCollectionsListView(
            type: type,
            title: type.rawValue,
            viewModel: viewModel.songsCollectionsListViewModel(for: type)
        )
    }

    private var quickDigView: some View {
        QueriedSongsListViewContainer(
            title: "Quick Dig",
            songs: viewModel.quickDigSongs,
            predicates: viewModel.quickDigPredicates
        )
    }

    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
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
