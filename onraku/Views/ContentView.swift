//
//  ContentView.swift
//  onraku
//
//  Created by Satoru Abe on 2022/02/11.
//

import MediaPlayer
import SwiftUI

struct ContentView: View {
  private enum Tab {
    case Library, NowPlaying
  }

  @State private var selectedTab: Tab = .Library

  var body: some View {
    ZStack {
      TabView(selection: $selectedTab) {
        NavigationView {
          List {
            ForEach(CollectionType.allCases, id: \.self) { type in
              NavigationLink {
                SongsCollectionsListView(type: type, title: type.rawValue)
              } label: {
                Label(type.rawValue, systemImage: type.systemImageName)
              }
            }
          }.navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }.tabItem {
          Image(systemName: "books.vertical")
            .environment(
              \.symbolVariants, selectedTab == .Library ? .fill : .none)
          Text("Library")
        }.tag(Tab.Library)

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
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
