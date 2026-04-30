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

  @StateObject private var viewModel = ContentViewModel()

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
                    viewModel: viewModel.songsCollectionsListViewModel(for: type)
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
    .onAppear {
      viewModel.onAppear()
    }
    .onDisappear {
      viewModel.onDisappear()
    }
    .onChange(of: scenePhase) { _, newPhase in
      Task { await viewModel.handleScenePhaseChange(newPhase) }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
